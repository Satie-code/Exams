const prisma = require("../config/prisma");

const formatStudentExam = (allocation) => ({
  exam_id: allocation.examId,
  subject: allocation.exam.subject,
  date: allocation.exam.examDate.toISOString().split("T")[0],
  time: allocation.exam.examTime,
  room: allocation.room,
  seat: allocation.seat
});

const getAssignedExams = async (req, res, next) => {
  try {
    const allocations = await prisma.seatingAllocation.findMany({
      where: {
        student: {
          is: {
            userId: req.user.user_id
          }
        }
      },
      select: {
        examId: true,
        room: true,
        seat: true,
        exam: {
          select: {
            subject: true,
            examDate: true,
            examTime: true
          }
        }
      }
    });

    const exams = allocations
      .map(formatStudentExam)
      .sort((left, right) => {
        const leftDateTime = `${left.date} ${left.time}`;
        const rightDateTime = `${right.date} ${right.time}`;

        return leftDateTime.localeCompare(rightDateTime);
      });

    return res.status(200).json({ exams });
  } catch (error) {
    return next(error);
  }
};

const getStudentSeating = async (req, res, next) => {
  try {
    const examId = Number(req.query.exam_id);

    if (!req.query.exam_id || Number.isNaN(examId) || examId <= 0) {
      return res.status(400).json({
        message: "A valid exam_id query parameter is required"
      });
    }

    const allocation = await prisma.seatingAllocation.findFirst({
      where: {
        examId,
        student: {
          is: {
            userId: req.user.user_id
          }
        }
      },
      select: {
        examId: true,
        room: true,
        seat: true,
        exam: {
          select: {
            subject: true,
            examDate: true,
            examTime: true
          }
        }
      }
    });

    if (!allocation) {
      return res.status(404).json({
        message: "Seating allocation not found for this exam"
      });
    }

    return res.status(200).json(formatStudentExam(allocation));
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getAssignedExams,
  getStudentSeating
};
