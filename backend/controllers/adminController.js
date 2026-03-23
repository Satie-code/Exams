const prisma = require("../config/prisma");
const { createHttpError } = require("./facultyController");

const approveDutySwap = async (req, res, next) => {
  try {
    const swapRequestId = Number(req.body.swap_request_id);
    const approved = req.body.approved;

    if (Number.isNaN(swapRequestId) || swapRequestId <= 0) {
      return res.status(400).json({
        message: "A valid swap_request_id is required"
      });
    }

    if (typeof approved !== "boolean") {
      return res.status(400).json({
        message: "approved must be a boolean value"
      });
    }

    const result = await prisma.$transaction(async (tx) => {
      const swapRequest = await tx.dutySwapRequest.findUnique({
        where: { id: swapRequestId },
        select: {
          id: true,
          status: true,
          requesterDutyId: true,
          targetDutyId: true,
          requesterDuty: {
            select: {
              id: true,
              facultyId: true
            }
          },
          targetDuty: {
            select: {
              id: true,
              facultyId: true
            }
          }
        }
      });

      if (!swapRequest) {
        throw createHttpError(404, "Swap request not found");
      }

      if (swapRequest.status !== "PENDING") {
        throw createHttpError(409, "This swap request has already been processed");
      }

      if (approved) {
        await tx.duty.update({
          where: { id: swapRequest.requesterDutyId },
          data: {
            facultyId: swapRequest.targetDuty.facultyId,
            status: "CONFIRMED"
          }
        });

        await tx.duty.update({
          where: { id: swapRequest.targetDutyId },
          data: {
            facultyId: swapRequest.requesterDuty.facultyId,
            status: "CONFIRMED"
          }
        });

        await tx.dutySwapRequest.update({
          where: { id: swapRequestId },
          data: {
            status: "APPROVED"
          }
        });

        return {
          status: "APPROVED"
        };
      }

      await tx.duty.update({
        where: { id: swapRequest.requesterDutyId },
        data: {
          status: "CONFIRMED"
        }
      });

      await tx.duty.update({
        where: { id: swapRequest.targetDutyId },
        data: {
          status: "CONFIRMED"
        }
      });

      await tx.dutySwapRequest.update({
        where: { id: swapRequestId },
        data: {
          status: "REJECTED"
        }
      });

      return {
        status: "REJECTED"
      };
    });

    return res.status(200).json({
      message:
        result.status === "APPROVED"
          ? "Duty swap approved successfully"
          : "Duty swap rejected successfully",
      swap_request_id: swapRequestId,
      status: result.status
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  approveDutySwap
};
