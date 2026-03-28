const prisma = require("../config/prisma");
const { getIO } = require("../config/socket");

const WARNING_SECONDS = 5 * 60;
const VIOLATION_SECONDS = 10 * 60;
const ALLOWED_SOS_MESSAGES = new Set([
  "ANSWER_SHEETS",
  "STATIONERY",
  "URGENT_HELP"
]);

const getFacultyProfile = async (userId) =>
  prisma.faculty.findUnique({
    where: { userId },
    select: { id: true, name: true }
  });

const getFacultyDutyOrThrow = async (userId, dutyId) => {
  const faculty = await getFacultyProfile(userId);

  if (!faculty) {
    const error = new Error("Faculty profile not found");
    error.statusCode = 404;
    throw error;
  }

  const duty = await prisma.duty.findFirst({
    where: {
      id: dutyId,
      facultyId: faculty.id
    },
    select: {
      id: true,
      facultyId: true,
      room: true,
      examId: true,
      exam: {
        select: {
          subject: true
        }
      }
    }
  });

  if (!duty) {
    const error = new Error("Duty not found for this faculty member");
    error.statusCode = 404;
    throw error;
  }

  return {
    faculty,
    duty
  };
};

const parseDutyId = (value) => {
  const dutyId = Number(value);

  if (Number.isNaN(dutyId) || dutyId <= 0) {
    return null;
  }

  return dutyId;
};

const normalizeStudentIdentifier = (value) => {
  if (!value || typeof value !== "string") {
    return null;
  }

  const normalizedValue = value.trim();
  return normalizedValue.length > 0 ? normalizedValue : null;
};

const normalizeBundleId = (value) => {
  if (!value || typeof value !== "string") {
    return null;
  }

  const normalizedValue = value.trim();
  return normalizedValue.length > 0 ? normalizedValue : null;
};

const normalizeSOSMessage = (value) => {
  if (!value || typeof value !== "string") {
    return null;
  }

  const normalizedValue = value.trim().toUpperCase();
  return ALLOWED_SOS_MESSAGES.has(normalizedValue) ? normalizedValue : null;
};

const normalizeOptionalText = (value) => {
  if (typeof value !== "string") {
    return null;
  }

  const normalizedValue = value.trim();
  return normalizedValue.length > 0 ? normalizedValue : null;
};

const parseNonNegativeInteger = (value) => {
  const parsedValue = Number(value);

  if (!Number.isInteger(parsedValue) || parsedValue < 0) {
    return null;
  }

  return parsedValue;
};

const getWashroomMetrics = (startTime, endTime = null) => {
  const effectiveEndTime = endTime ? endTime.getTime() : Date.now();
  const durationSeconds = Math.max(
    0,
    Math.floor((effectiveEndTime - startTime.getTime()) / 1000)
  );

  if (endTime) {
    return {
      duration_seconds: durationSeconds,
      status: durationSeconds >= VIOLATION_SECONDS ? "VIOLATION" : "RETURNED",
      state: durationSeconds >= VIOLATION_SECONDS ? "red" : "green"
    };
  }

  if (durationSeconds >= VIOLATION_SECONDS) {
    return {
      duration_seconds: durationSeconds,
      status: "VIOLATION",
      state: "red"
    };
  }

  if (durationSeconds >= WARNING_SECONDS) {
    return {
      duration_seconds: durationSeconds,
      status: "WARNING",
      state: "yellow"
    };
  }

  return {
    duration_seconds: durationSeconds,
    status: "ACTIVE",
    state: "green"
  };
};

const serializeWashroomLog = (log) => {
  const metrics = getWashroomMetrics(log.startTime, log.endTime);

  return {
    log_id: log.id,
    student_id: log.studentId,
    start_time: log.startTime.toISOString(),
    end_time: log.endTime ? log.endTime.toISOString() : null,
    duration_seconds: metrics.duration_seconds,
    status: log.endTime ? log.status : metrics.status,
    state: metrics.state
  };
};

const createActivity = async (tx, { facultyId, dutyId, type, message }) => {
  const activity = await tx.activityLog.create({
    data: {
      facultyId,
      dutyId,
      type,
      message
    },
    include: {
      faculty: { select: { name: true } }
    }
  });

  try {
    getIO().to("admin_room").emit("ACTIVITY_LOGGED", {
      id: activity.id,
      type: activity.type,
      message: activity.message,
      faculty: { name: activity.faculty?.name || "Unknown Faculty" },
      created_at: activity.createdAt.toISOString()
    });
  } catch (err) {
    console.error("Socket emit failed from createActivity:", err.message);
  }

  return activity;
};

const scanBundle = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const bundleId = normalizeBundleId(req.body.bundle_id);

    if (!dutyId || !bundleId) {
      return res.status(400).json({
        message: "duty_id and bundle_id are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);
    const bundle = await prisma.bundle.findUnique({
      where: {
        bundleId
      },
      select: {
        id: true,
        bundleId: true,
        room: true,
        examId: true,
        exam: {
          select: {
            subject: true
          }
        }
      }
    });

    if (!bundle) {
      return res.status(404).json({
        message: "Invalid bundle_id"
      });
    }

    if (bundle.examId !== duty.examId || bundle.room !== duty.room) {
      return res.status(409).json({
        message: `Bundle ${bundle.bundleId} is assigned to ${bundle.exam.subject} in room ${bundle.room}`
      });
    }

    const scanLog = await prisma.$transaction(async (tx) => {
      const createdScanLog = await tx.bundleScanLog.create({
        data: {
          bundleRecordId: bundle.id,
          facultyId: faculty.id,
          dutyId: duty.id
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "BUNDLE_SCANNED",
        message: `Bundle ${bundle.bundleId} scanned for ${bundle.exam.subject} in room ${bundle.room}`
      });

      return createdScanLog;
    });

    return res.status(201).json({
      message: "Bundle scanned successfully",
      scan_log_id: scanLog.id,
      scanned_at: scanLog.scannedAt.toISOString(),
      bundle: {
        bundle_id: bundle.bundleId,
        exam_id: bundle.examId,
        subject: bundle.exam.subject,
        room: bundle.room
      }
    });
  } catch (error) {
    return next(error);
  }
};

const markAttendance = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const studentIdentifier = normalizeStudentIdentifier(req.body.student_identifier);

    if (!dutyId || !studentIdentifier) {
      return res.status(400).json({
        message: "duty_id and student_identifier are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    await prisma.$transaction(async (tx) => {
      await tx.attendance.create({
        data: {
          facultyId: faculty.id,
          dutyId: duty.id,
          studentIdentifier
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "ATTENDANCE_MARKED",
        message: `Attendance marked for ${studentIdentifier}`
      });
    });

    return res.status(201).json({
      message: "Attendance marked successfully"
    });
  } catch (error) {
    return next(error);
  }
};

const requestSupplies = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const item = typeof req.body.item === "string" ? req.body.item.trim() : "";
    const quantity = Number(req.body.quantity);
    const note =
      typeof req.body.note === "string" && req.body.note.trim()
        ? req.body.note.trim()
        : null;

    if (!dutyId || !item || Number.isNaN(quantity) || quantity <= 0) {
      return res.status(400).json({
        message: "duty_id, item, and a valid quantity are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    await prisma.$transaction(async (tx) => {
      await tx.supplyRequest.create({
        data: {
          facultyId: faculty.id,
          dutyId: duty.id,
          item,
          quantity,
          note
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "SUPPLIES_REQUESTED",
        message: `Requested ${quantity} x ${item}`
      });
    });

    return res.status(201).json({
      message: "Supply request sent successfully"
    });
  } catch (error) {
    return next(error);
  }
};

const requestSOS = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const message = normalizeSOSMessage(req.body.message);

    if (!dutyId || !message) {
      return res.status(400).json({
        message: "duty_id and a valid SOS message are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    const sosRequest = await prisma.$transaction(async (tx) => {
      const createdRequest = await tx.sOSRequest.create({
        data: {
          facultyId: faculty.id,
          message,
          status: "PENDING"
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "SOS_REQUESTED",
        message: `SOS requested: ${message.replace(/_/g, " ").toLowerCase()}`
      });

      return createdRequest;
    });

    const pendingCount = await prisma.sOSRequest.count({
      where: {
        facultyId: faculty.id,
        status: "PENDING"
      }
    });

    try {
      getIO().to("admin_room").emit("NEW_SOS", {
        request_id: sosRequest.id,
        faculty_name: faculty.name || "Unknown Faculty",
        room: duty.room,
        message: sosRequest.message,
        status: sosRequest.status,
        created_at: sosRequest.createdAt.toISOString()
      });
    } catch(err) {
      console.error("Socket emit failed:", err.message);
    }

    return res.status(201).json({
      message: "SOS request submitted",
      sos_request: {
        request_id: sosRequest.id,
        faculty_id: sosRequest.facultyId,
        message: sosRequest.message,
        status: sosRequest.status,
        created_at: sosRequest.createdAt.toISOString()
      },
      pending_count: pendingCount
    });
  } catch (error) {
    return next(error);
  }
};

const submitReport = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const totalStudentsPresent = parseNonNegativeInteger(
      req.body.total_students_present
    );
    const totalAnswerSheetsCollected = parseNonNegativeInteger(
      req.body.total_answer_sheets_collected
    );
    const noIncidents =
      typeof req.body.no_incidents === "boolean" ? req.body.no_incidents : null;
    const incidentDetails = normalizeOptionalText(req.body.incident_details);
    const remarks = normalizeOptionalText(req.body.remarks);
    const declarationAccepted = req.body.declaration_accepted === true;

    if (
      !dutyId ||
      totalStudentsPresent === null ||
      totalAnswerSheetsCollected === null ||
      noIncidents === null
    ) {
      return res.status(400).json({
        message:
          "duty_id, attendance summary, sheet count, and incidents are required"
      });
    }

    if (!declarationAccepted) {
      return res.status(400).json({
        message: "Declaration acceptance is required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    const report = await prisma.$transaction(async (tx) => {
      const createdReport = await tx.postExamReport.create({
        data: {
          facultyId: faculty.id,
          dutyId: duty.id,
          totalStudentsPresent,
          totalAnswerSheetsCollected,
          noIncidents,
          incidentDetails,
          remarks,
          declarationAccepted
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "REPORT_SUBMITTED",
        message: `Post-exam report submitted for ${duty.exam.subject}`
      });

      return createdReport;
    });

    return res.status(201).json({
      message: "Post-exam report submitted successfully",
      report: {
        report_id: report.id,
        duty_id: report.dutyId,
        total_students_present: report.totalStudentsPresent,
        total_answer_sheets_collected: report.totalAnswerSheetsCollected,
        no_incidents: report.noIncidents,
        incident_details: report.incidentDetails,
        remarks: report.remarks,
        declaration_accepted: report.declarationAccepted,
        created_at: report.createdAt.toISOString()
      }
    });
  } catch (error) {
    return next(error);
  }
};

const startWashroomTimer = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const studentId = normalizeStudentIdentifier(req.body.student_id);

    if (!dutyId || !studentId) {
      return res.status(400).json({
        message: "duty_id and student_id are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    const existingLog = await prisma.washroomLog.findFirst({
      where: {
        dutyId: duty.id,
        studentId,
        endTime: null
      }
    });

    if (existingLog) {
      return res.status(409).json({
        message: "This student already has an active washroom timer"
      });
    }

    const log = await prisma.$transaction(async (tx) => {
      const createdLog = await tx.washroomLog.create({
        data: {
          facultyId: faculty.id,
          dutyId: duty.id,
          studentId,
          status: "ACTIVE"
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "WASHROOM_STARTED",
        message: `Washroom timer started for ${studentId}`
      });

      return createdLog;
    });

    return res.status(201).json({
      message: "Washroom timer started",
      washroom_log: serializeWashroomLog(log)
    });
  } catch (error) {
    return next(error);
  }
};

const endWashroomTimer = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const studentId = normalizeStudentIdentifier(req.body.student_id);

    if (!dutyId || !studentId) {
      return res.status(400).json({
        message: "duty_id and student_id are required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    const activeLog = await prisma.washroomLog.findFirst({
      where: {
        facultyId: faculty.id,
        dutyId: duty.id,
        studentId,
        endTime: null
      }
    });

    if (!activeLog) {
      return res.status(404).json({
        message: "No active washroom timer found for this student"
      });
    }

    const endTime = new Date();
    const metrics = getWashroomMetrics(activeLog.startTime, endTime);

    const log = await prisma.$transaction(async (tx) => {
      const updatedLog = await tx.washroomLog.update({
        where: { id: activeLog.id },
        data: {
          endTime,
          status: metrics.status
        }
      });

      await createActivity(tx, {
        facultyId: faculty.id,
        dutyId: duty.id,
        type: "WASHROOM_ENDED",
        message: `Washroom timer ended for ${studentId} (${metrics.status.toLowerCase()})`
      });

      return updatedLog;
    });

    return res.status(200).json({
      message: "Washroom timer ended",
      washroom_log: serializeWashroomLog(log)
    });
  } catch (error) {
    return next(error);
  }
};

const getActivity = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.query.duty_id);

    if (!dutyId) {
      return res.status(400).json({
        message: "A valid duty_id query parameter is required"
      });
    }

    const { faculty, duty } = await getFacultyDutyOrThrow(req.user.user_id, dutyId);

    const [activities, activeLogs, pendingSOSCount, registeredCount] =
      await Promise.all([
      prisma.activityLog.findMany({
        where: {
          facultyId: faculty.id,
          dutyId: duty.id
        },
        orderBy: {
          createdAt: "desc"
        },
        take: 10
      }),
      prisma.washroomLog.findMany({
        where: {
          facultyId: faculty.id,
          dutyId: duty.id,
          endTime: null
        },
        orderBy: {
          startTime: "asc"
        }
      }),
      prisma.sOSRequest.count({
        where: {
          facultyId: faculty.id,
          status: "PENDING"
        }
      }),
      prisma.seatingAllocation.count({
        where: {
          examId: duty.examId,
          room: duty.room
        }
      })
    ]);

    return res.status(200).json({
      duty: {
        duty_id: duty.id,
        exam_id: duty.examId,
        subject: duty.exam.subject,
        room: duty.room
      },
      registered_count: registeredCount,
      max_capacity: registeredCount,
      pending_sos_count: pendingSOSCount,
      washroom_logs: activeLogs.map((log) => serializeWashroomLog(log)),
      activities: activities.map((activity) => ({
        id: activity.id,
        type: activity.type,
        message: activity.message,
        created_at: activity.createdAt.toISOString()
      }))
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  scanBundle,
  markAttendance,
  requestSupplies,
  requestSOS,
  submitReport,
  startWashroomTimer,
  endWashroomTimer,
  getActivity
};
