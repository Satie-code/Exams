const prisma = require("../config/prisma");

const getFacultyProfile = async (userId) =>
  prisma.faculty.findUnique({
    where: { userId },
    select: { id: true, name: true }
  });

const getFacultyDutyOrThrow = async (userId, dutyId) => {
  const faculty = await getFacultyProfile(userId);

  if (!faculty) {
    const error = new Error("Faculty profile not found");
    error.statusCode = 404;
    throw error;
  }

  const duty = await prisma.duty.findFirst({
    where: {
      id: dutyId,
      facultyId: faculty.id
    },
    select: {
      id: true,
      facultyId: true,
      room: true,
      examId: true,
      exam: {
        select: {
          subject: true
        }
      }
    }
  });

  if (!duty) {
    const error = new Error("Duty not found for this faculty member");
    error.statusCode = 404;
    throw error;
  }

  return {
    faculty,
    duty
  };
};

module.exports = {
  getFacultyProfile,
  getFacultyDutyOrThrow
};
