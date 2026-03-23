const prisma = require("../config/prisma");

const DUTY_SELECT = {
  id: true,
  examId: true,
  room: true,
  role: true,
  status: true,
  exam: {
    select: {
      subject: true,
      examDate: true,
      examTime: true
    }
  }
};

const SWAP_OPTION_SELECT = {
  id: true,
  examId: true,
  room: true,
  role: true,
  exam: {
    select: {
      subject: true,
      examDate: true,
      examTime: true
    }
  }
};

const createHttpError = (statusCode, message) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const formatDuty = (duty) => ({
  duty_id: duty.id,
  exam_id: duty.examId,
  subject: duty.exam.subject,
  date: duty.exam.examDate.toISOString().split("T")[0],
  time: duty.exam.examTime,
  room: duty.room,
  role: duty.role,
  status: duty.status
});

const formatSwapOption = (duty) => ({
  duty_id: duty.id,
  exam_id: duty.examId,
  subject: duty.exam.subject,
  date: duty.exam.examDate.toISOString().split("T")[0],
  time: duty.exam.examTime,
  room: duty.room,
  role: duty.role,
  status: "CONFIRMED"
});

const sortBySchedule = (left, right) => {
  const leftDateTime = `${left.date} ${left.time}`;
  const rightDateTime = `${right.date} ${right.time}`;

  return leftDateTime.localeCompare(rightDateTime);
};

const getFacultyProfile = async (userId) =>
  prisma.faculty.findUnique({
    where: { userId },
    select: { id: true }
  });

const getFacultyDuties = async (req, res, next) => {
  try {
    const faculty = await getFacultyProfile(req.user.user_id);

    if (!faculty) {
      return res.status(404).json({
        message: "Faculty profile not found"
      });
    }

    const duties = await prisma.duty.findMany({
      where: {
        facultyId: faculty.id
      },
      select: DUTY_SELECT
    });

    return res.status(200).json({
      duties: duties.map(formatDuty).sort(sortBySchedule)
    });
  } catch (error) {
    return next(error);
  }
};

const getDutySwapOptions = async (req, res, next) => {
  try {
    const dutyId = Number(req.query.duty_id);

    if (!req.query.duty_id || Number.isNaN(dutyId) || dutyId <= 0) {
      return res.status(400).json({
        message: "A valid duty_id query parameter is required"
      });
    }

    const requesterDuty = await prisma.duty.findUnique({
      where: { id: dutyId },
      select: {
        id: true,
        facultyId: true,
        status: true,
        faculty: {
          select: {
            userId: true
          }
        }
      }
    });

    if (!requesterDuty) {
      return res.status(404).json({
        message: "Duty not found"
      });
    }

    if (requesterDuty.faculty.userId !== req.user.user_id) {
      return res.status(403).json({
        message: "You can only request swaps for your own duties"
      });
    }

    if (requesterDuty.status !== "CONFIRMED") {
      return res.status(409).json({
        message: "Swap options are only available for confirmed duties"
      });
    }

    const swapOptions = await prisma.duty.findMany({
      where: {
        id: { not: dutyId },
        facultyId: { not: requesterDuty.facultyId },
        status: "CONFIRMED"
      },
      select: SWAP_OPTION_SELECT
    });

    return res.status(200).json({
      duty_id: dutyId,
      swap_options: swapOptions.map(formatSwapOption).sort(sortBySchedule)
    });
  } catch (error) {
    return next(error);
  }
};

const requestDutySwap = async (req, res, next) => {
  try {
    const requesterDutyId = Number(req.body.requester_duty_id);
    const targetDutyId = Number(req.body.target_duty_id);

    if (
      Number.isNaN(requesterDutyId) ||
      requesterDutyId <= 0 ||
      Number.isNaN(targetDutyId) ||
      targetDutyId <= 0
    ) {
      return res.status(400).json({
        message: "requester_duty_id and target_duty_id are required"
      });
    }

    if (requesterDutyId === targetDutyId) {
      return res.status(400).json({
        message: "Requester and target duties must be different"
      });
    }

    const duties = await prisma.duty.findMany({
      where: {
        id: {
          in: [requesterDutyId, targetDutyId]
        }
      },
      select: {
        id: true,
        facultyId: true,
        status: true,
        faculty: {
          select: {
            userId: true
          }
        }
      }
    });

    if (duties.length !== 2) {
      return res.status(404).json({
        message: "Both duties must exist to request a swap"
      });
    }

    const requesterDuty = duties.find((duty) => duty.id === requesterDutyId);
    const targetDuty = duties.find((duty) => duty.id === targetDutyId);

    if (!requesterDuty || !targetDuty) {
      return res.status(404).json({
        message: "Both duties must exist to request a swap"
      });
    }

    if (requesterDuty.faculty.userId !== req.user.user_id) {
      return res.status(403).json({
        message: "You can only request swaps for your own duties"
      });
    }

    if (requesterDuty.facultyId === targetDuty.facultyId) {
      return res.status(400).json({
        message: "Target duty must belong to another faculty member"
      });
    }

    if (requesterDuty.status !== "CONFIRMED" || targetDuty.status !== "CONFIRMED") {
      return res.status(409).json({
        message: "Only confirmed duties can be swapped"
      });
    }

    const pendingSwap = await prisma.dutySwapRequest.findFirst({
      where: {
        status: "PENDING",
        OR: [
          {
            requesterDutyId: {
              in: [requesterDutyId, targetDutyId]
            }
          },
          {
            targetDutyId: {
              in: [requesterDutyId, targetDutyId]
            }
          }
        ]
      }
    });

    if (pendingSwap) {
      return res.status(409).json({
        message: "A pending swap already exists for one of these duties"
      });
    }

    const swapRequest = await prisma.$transaction(async (tx) => {
      await tx.duty.update({
        where: { id: requesterDutyId },
        data: { status: "PENDING_SWAP" }
      });

      await tx.duty.update({
        where: { id: targetDutyId },
        data: { status: "PENDING_SWAP" }
      });

      return tx.dutySwapRequest.create({
        data: {
          requesterDutyId,
          targetDutyId,
          requestedByFacultyId: requesterDuty.facultyId
        },
        select: {
          id: true,
          status: true
        }
      });
    });

    return res.status(201).json({
      message: "Duty swap requested successfully",
      swap_request_id: swapRequest.id,
      status: swapRequest.status,
      duties: [
        {
          duty_id: requesterDutyId,
          status: "PENDING_SWAP"
        },
        {
          duty_id: targetDutyId,
          status: "PENDING_SWAP"
        }
      ]
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getFacultyDuties,
  getDutySwapOptions,
  requestDutySwap,
  createHttpError
};
