const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { serializeWashroomLog } = require("./washroomService");

const getDutyOperationalSummary = async ({ userId, dutyId }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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

  return {
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
  };
};

module.exports = {
  getDutyOperationalSummary
};
