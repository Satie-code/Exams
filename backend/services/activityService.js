const { getIO } = require("../config/socket");

/**
 * Creates an activity log entry and broadcasts to admin_room.
 * Uses the passed Prisma transaction client.
 */
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

module.exports = {
  createActivity
};
