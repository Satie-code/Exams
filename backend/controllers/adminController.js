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

const getDashboard = async (req, res, next) => {
  try {
    const pendingSOS = await prisma.sOSRequest.findMany({
      where: { status: "PENDING" },
      include: { faculty: { select: { id: true, name: true, department: true } } },
      orderBy: { createdAt: "desc" }
    });

    const activeWashrooms = await prisma.washroomLog.findMany({
      where: { endTime: null },
      include: { student: { select: { id: true, name: true, rollNumber: true } } },
      orderBy: { startTime: "desc" }
    });

    const recentActivities = await prisma.activityLog.findMany({
      take: 50,
      orderBy: { createdAt: "desc" },
      include: { faculty: { select: { name: true } } }
    });

    const pendingSwaps = await prisma.dutySwapRequest.findMany({
      where: { status: "PENDING" },
      include: {
        requesterFaculty: { select: { name: true } },
        targetDuty: { select: { exam: { select: { subject: true } }, room: true } }
      }
    });

    return res.status(200).json({
      pending_sos: pendingSOS,
      active_washrooms: activeWashrooms,
      recent_activities: recentActivities,
      pending_swaps: pendingSwaps
    });
  } catch (error) {
    return next(error);
  }
};

const resolveSOS = async (req, res, next) => {
  try {
    const requestId = Number(req.params.id);
    if (!requestId) {
      return res.status(400).json({ message: "Invalid SOS ID" });
    }

    const updated = await prisma.sOSRequest.update({
      where: { id: requestId },
      data: { status: "RESOLVED" }
    });

    // We could emit a SOCKET event here, but the active SOS alert list on the client
    // is usually synced immediately manually inside the client state or by triggering a reload.
    // Given the architecture, client-side filtering works perfectly.

    return res.status(200).json({
      message: "SOS resolved successfully",
      sos_request: updated
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  approveDutySwap,
  getDashboard,
  resolveSOS
};
