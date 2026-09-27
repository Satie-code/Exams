const {
  processBundleScan
} = require("../services/bundleService");
const {
  recordAttendance
} = require("../services/attendanceService");
const {
  createSupplyRequest
} = require("../services/supplyService");
const {
  createSOSRequest
} = require("../services/sosService");
const {
  createPostExamReport
} = require("../services/reportService");
const {
  startWashroom,
  endWashroom
} = require("../services/washroomService");
const {
  getDutyOperationalSummary
} = require("../services/dashboardService");

const ALLOWED_SOS_MESSAGES = new Set([
  "ANSWER_SHEETS",
  "STATIONERY",
  "URGENT_HELP"
]);

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

const scanBundle = async (req, res, next) => {
  try {
    const dutyId = parseDutyId(req.body.duty_id);
    const bundleId = normalizeBundleId(req.body.bundle_id);

    if (!dutyId || !bundleId) {
      return res.status(400).json({
        message: "duty_id and bundle_id are required"
      });
    }

    const { scanLog, bundle } = await processBundleScan({
      userId: req.user.user_id,
      dutyId,
      bundleId
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
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    await recordAttendance({
      userId: req.user.user_id,
      dutyId,
      studentIdentifier
    });

    return res.status(201).json({
      message: "Attendance marked successfully"
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    await createSupplyRequest({
      userId: req.user.user_id,
      dutyId,
      item,
      quantity,
      note
    });

    return res.status(201).json({
      message: "Supply request sent successfully"
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    const { sosRequest, pendingCount } = await createSOSRequest({
      userId: req.user.user_id,
      dutyId,
      message
    });

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
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    const report = await createPostExamReport({
      userId: req.user.user_id,
      dutyId,
      totalStudentsPresent,
      totalAnswerSheetsCollected,
      noIncidents,
      incidentDetails,
      remarks,
      declarationAccepted
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
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    const washroomLog = await startWashroom({
      userId: req.user.user_id,
      dutyId,
      studentId
    });

    return res.status(201).json({
      message: "Washroom timer started",
      washroom_log: washroomLog
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    const washroomLog = await endWashroom({
      userId: req.user.user_id,
      dutyId,
      studentId
    });

    return res.status(200).json({
      message: "Washroom timer ended",
      washroom_log: washroomLog
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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

    const summary = await getDutyOperationalSummary({
      userId: req.user.user_id,
      dutyId
    });

    return res.status(200).json(summary);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
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
