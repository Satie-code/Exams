const prisma = require("../config/prisma");
const { getFacultyDutyOrThrow } = require("./dutyService");
const { createActivity } = require("./activityService");

const createSupplyRequest = async ({ userId, dutyId, item, quantity, note }) => {
  const { faculty, duty } = await getFacultyDutyOrThrow(userId, dutyId);

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

  return { success: true };
};

module.exports = {
  createSupplyRequest
};
