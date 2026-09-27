const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const WARNING_SECONDS = 5 * 60;
const VIOLATION_SECONDS = 10 * 60;

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

const startWashroom = async ({ userId, dutyId, studentId }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

  const existingLog = await prisma.washroomLog.findFirst({
    where: {
      dutyId: duty.id,
      studentId,
      endTime: null
    }
  });

  if (existingLog) {
    const error = new Error("This student already has an active washroom timer");
    error.statusCode = 409;
    throw error;
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

  return serializeWashroomLog(log);
};

const endWashroom = async ({ userId, dutyId, studentId }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

  const activeLog = await prisma.washroomLog.findFirst({
    where: {
      facultyId: faculty.id,
      dutyId: duty.id,
      studentId,
      endTime: null
    }
  });

  if (!activeLog) {
    const error = new Error("No active washroom timer found for this student");
    error.statusCode = 404;
    throw error;
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

  return serializeWashroomLog(log);
};

module.exports = {
  WARNING_SECONDS,
  VIOLATION_SECONDS,
  getWashroomMetrics,
  serializeWashroomLog,
  startWashroom,
  endWashroom
};
