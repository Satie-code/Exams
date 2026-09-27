const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const recordAttendance = async ({ userId, dutyId, studentIdentifier }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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

  return { success: true };
};

module.exports = {
  recordAttendance
};
