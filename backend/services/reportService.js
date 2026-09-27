const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const createPostExamReport = async ({
  userId,
  dutyId,
  totalStudentsPresent,
  totalAnswerSheetsCollected,
  noIncidents,
  incidentDetails,
  remarks,
  declarationAccepted
}) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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

  return report;
};

module.exports = {
  createPostExamReport
};
