const prisma = require("../config/prisma");
const { getIO } = require("../config/socket");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const createSOSRequest = async ({ userId, dutyId, message }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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
  } catch (err) {
    console.error("Socket emit failed:", err.message);
  }

  return {
    sosRequest,
    pendingCount
  };
};

module.exports = {
  createSOSRequest
};
