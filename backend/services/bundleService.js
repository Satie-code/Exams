const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const processBundleScan = async ({ userId, dutyId, bundleId }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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
    const error = new Error("Invalid bundle_id");
    error.statusCode = 404;
    throw error;
  }

  if (bundle.examId !== duty.examId || bundle.room !== duty.room) {
    const error = new Error(
      `Bundle ${bundle.bundleId} is assigned to ${bundle.exam.subject} in room ${bundle.room}`
    );
    error.statusCode = 409;
    throw error;
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

  return {
    scanLog,
    bundle
  };
};

module.exports = {
  processBundleScan
};
