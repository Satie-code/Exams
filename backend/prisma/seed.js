const bcrypt = require("bcrypt");

const prisma = require("../config/prisma");

const DEMO_PASSWORD = "Pass123!";

const startOfDay = (value) =>
  new Date(value.getFullYear(), value.getMonth(), value.getDate());

const plusDays = (value, days) => {
  const result = new Date(value);
  result.setDate(result.getDate() + days);
  return result;
};

const setClock = (value, hour, minute) =>
  new Date(
    value.getFullYear(),
    value.getMonth(),
    value.getDate(),
    hour,
    minute,
    0,
    0
  );

const formatTime = (value) => {
  const hours24 = value.getHours();
  const minutes = value.getMinutes().toString().padStart(2, "0");
  const suffix = hours24 >= 12 ? "PM" : "AM";
  const hours12 = hours24 % 12 === 0 ? 12 : hours24 % 12;
  return `${hours12.toString().padStart(2, "0")}:${minutes} ${suffix}`;
};

const formatRange = (start, end) => `${formatTime(start)} - ${formatTime(end)}`;

async function resetData() {
  await prisma.activityLog.deleteMany();
  await prisma.postExamReport.deleteMany();
  await prisma.sOSRequest.deleteMany();
  await prisma.washroomLog.deleteMany();
  await prisma.supplyRequest.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.bundleScanLog.deleteMany();
  await prisma.dutySwapRequest.deleteMany();
  await prisma.duty.deleteMany();
  await prisma.bundle.deleteMany();
  await prisma.seatingAllocation.deleteMany();
  await prisma.exam.deleteMany();
  await prisma.faculty.deleteMany();
  await prisma.student.deleteMany();
  await prisma.user.deleteMany();
}

async function createUsers(hashedPassword) {
  const studentUser = await prisma.user.create({
    data: {
      email: "student@exams.local",
      password: hashedPassword,
      role: "STUDENT",
      student: {
        create: {}
      }
    },
    include: {
      student: true
    }
  });

  const facultyUser = await prisma.user.create({
    data: {
      email: "faculty@exams.local",
      password: hashedPassword,
      role: "FACULTY",
      faculty: {
        create: {}
      }
    },
    include: {
      faculty: true
    }
  });

  const alternateFacultyUser = await prisma.user.create({
    data: {
      email: "faculty2@exams.local",
      password: hashedPassword,
      role: "FACULTY",
      faculty: {
        create: {}
      }
    },
    include: {
      faculty: true
    }
  });

  const adminUser = await prisma.user.create({
    data: {
      email: "admin@exams.local",
      password: hashedPassword,
      role: "ADMIN"
    }
  });

  return {
    adminUser,
    studentUser,
    facultyUser,
    alternateFacultyUser
  };
}

async function createExams() {
  const now = new Date();
  const today = startOfDay(now);

  const activeReferenceHour = Math.max(2, Math.min(21, now.getHours()));
  const activeStart = setClock(today, activeReferenceHour - 1, 0);
  const activeEnd = setClock(today, activeReferenceHour + 2, 0);

  const futureOneDay = plusDays(today, 1);
  const futureTwoDays = plusDays(today, 2);
  const futureThreeDays = plusDays(today, 3);
  const pastOneDay = plusDays(today, -1);

  const activeExam = await prisma.exam.create({
    data: {
      subject: "MATH101 - Applied Mathematics",
      examDate: today,
      examTime: formatRange(activeStart, activeEnd)
    }
  });

  const studentExam = await prisma.exam.create({
    data: {
      subject: "CS101 - Intro to Computer Science",
      examDate: futureOneDay,
      examTime: formatRange(setClock(futureOneDay, 9, 0), setClock(futureOneDay, 12, 0))
    }
  });

  const pendingExam = await prisma.exam.create({
    data: {
      subject: "CS204 - Data Structures",
      examDate: futureTwoDays,
      examTime: formatRange(setClock(futureTwoDays, 14, 0), setClock(futureTwoDays, 17, 0))
    }
  });

  const swapTargetExam = await prisma.exam.create({
    data: {
      subject: "ENG201 - Technical Writing",
      examDate: futureThreeDays,
      examTime: formatRange(
        setClock(futureThreeDays, 10, 0),
        setClock(futureThreeDays, 13, 0)
      )
    }
  });

  const historyExam = await prisma.exam.create({
    data: {
      subject: "MATH302 - Discrete Mathematics",
      examDate: pastOneDay,
      examTime: formatRange(setClock(pastOneDay, 10, 0), setClock(pastOneDay, 13, 0))
    }
  });

  return {
    activeExam,
    studentExam,
    pendingExam,
    swapTargetExam,
    historyExam
  };
}

async function main() {
  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);

  await resetData();

  const {
    studentUser,
    facultyUser,
    alternateFacultyUser
  } = await createUsers(hashedPassword);
  const {
    activeExam,
    studentExam,
    pendingExam,
    swapTargetExam,
    historyExam
  } = await createExams();

  await prisma.seatingAllocation.createMany({
    data: [
      {
        studentId: studentUser.student.id,
        examId: studentExam.id,
        room: "Hall B-12",
        seat: "A-42"
      },
      {
        studentId: studentUser.student.id,
        examId: activeExam.id,
        room: "Hall 402",
        seat: "C-18"
      }
    ]
  });

  const activeDuty = await prisma.duty.create({
    data: {
      facultyId: facultyUser.faculty.id,
      examId: activeExam.id,
      room: "Hall 402",
      role: "INVIGILATOR",
      status: "CONFIRMED"
    }
  });

  await prisma.duty.create({
    data: {
      facultyId: facultyUser.faculty.id,
      examId: studentExam.id,
      room: "Hall A, Room 302",
      role: "INVIGILATOR",
      status: "CONFIRMED"
    }
  });

  const pendingDuty = await prisma.duty.create({
    data: {
      facultyId: facultyUser.faculty.id,
      examId: pendingExam.id,
      room: "Lab 2, Main Building",
      role: "LEAD",
      status: "PENDING_SWAP"
    }
  });

  const swapTargetDuty = await prisma.duty.create({
    data: {
      facultyId: alternateFacultyUser.faculty.id,
      examId: swapTargetExam.id,
      room: "North Annex Hall",
      role: "INVIGILATOR",
      status: "PENDING_SWAP"
    }
  });

  await prisma.duty.create({
    data: {
      facultyId: facultyUser.faculty.id,
      examId: historyExam.id,
      room: "Auditorium 1",
      role: "INVIGILATOR",
      status: "CONFIRMED"
    }
  });

  await prisma.duty.create({
    data: {
      facultyId: alternateFacultyUser.faculty.id,
      examId: studentExam.id,
      room: "Hall 5",
      role: "INVIGILATOR",
      status: "CONFIRMED"
    }
  });

  await prisma.dutySwapRequest.create({
    data: {
      requesterDutyId: pendingDuty.id,
      targetDutyId: swapTargetDuty.id,
      requestedByFacultyId: facultyUser.faculty.id,
      status: "PENDING"
    }
  });

  const correctBundle = await prisma.bundle.create({
    data: {
      bundleId: "BND-MATH101-001",
      examId: activeExam.id,
      room: "Hall 402"
    }
  });

  await prisma.bundle.create({
    data: {
      bundleId: "BND-MATH101-404",
      examId: activeExam.id,
      room: "Hall 101"
    }
  });

  await prisma.activityLog.createMany({
    data: [
      {
        facultyId: facultyUser.faculty.id,
        dutyId: activeDuty.id,
        type: "ATTENDANCE_MARKED",
        message: "Attendance scan complete: ID 55210"
      },
      {
        facultyId: facultyUser.faculty.id,
        dutyId: activeDuty.id,
        type: "BUNDLE_SCANNED",
        message: "Materials verified for Row B"
      }
    ]
  });

  await prisma.washroomLog.create({
    data: {
      facultyId: facultyUser.faculty.id,
      dutyId: activeDuty.id,
      studentId: "44921",
      startTime: new Date(Date.now() - 8 * 60 * 1000),
      status: "WARNING"
    }
  });

  await prisma.sOSRequest.createMany({
    data: [
      {
        facultyId: facultyUser.faculty.id,
        message: "ANSWER_SHEETS",
        status: "PENDING"
      },
      {
        facultyId: facultyUser.faculty.id,
        message: "STATIONERY",
        status: "PENDING"
      }
    ]
  });

  console.log("Seed complete.");
  console.log("Demo credentials:");
  console.log("  student@exams.local / Pass123!");
  console.log("  faculty@exams.local / Pass123!");
  console.log("  faculty2@exams.local / Pass123!");
  console.log("  admin@exams.local / Pass123!");
  console.log(`Active bundle for faculty testing: ${correctBundle.bundleId}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
