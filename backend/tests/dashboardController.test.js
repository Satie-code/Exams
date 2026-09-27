jest.mock("../config/prisma", () => ({
  faculty: {
    findUnique: jest.fn()
  },
  duty: {
    findFirst: jest.fn()
  },
  bundle: {
    findUnique: jest.fn()
  },
  sOSRequest: {
    create: jest.fn(),
    count: jest.fn()
  },
  postExamReport: {
    create: jest.fn()
  },
  washroomLog: {
    findFirst: jest.fn(),
    findMany: jest.fn()
  },
  seatingAllocation: {
    count: jest.fn()
  },
  activityLog: {
    findMany: jest.fn()
  },
  $transaction: jest.fn()
}));

const prisma = require("../config/prisma");
const {
  endWashroomTimer,
  getActivity,
  requestSOS,
  scanBundle,
  submitReport,
  startWashroomTimer
} = require("../controllers/dashboardController");
const { createMockResponse } = require("./helpers/httpMocks");

describe("dashboardController", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("rejects a scan when the bundle belongs to a different room", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });
    prisma.bundle.findUnique.mockResolvedValue({
      id: 21,
      bundleId: "BND-404",
      room: "B-302",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });

    const req = {
      body: {
        duty_id: 8,
        bundle_id: "BND-404"
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await scanBundle(req, res, next);

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      message: "Bundle BND-404 is assigned to Physics in room B-302"
    });
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(next).not.toHaveBeenCalled();
  });

  it("logs a successful scan for the matching duty room", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });
    prisma.bundle.findUnique.mockResolvedValue({
      id: 21,
      bundleId: "BND-200",
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });

    const scanTimestamp = new Date("2026-03-22T05:00:00.000Z");
    const tx = {
      bundleScanLog: {
        create: jest.fn().mockResolvedValue({
          id: 300,
          scannedAt: scanTimestamp
        })
      },
      activityLog: {
        create: jest.fn().mockResolvedValue({})
      }
    };

    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        duty_id: 8,
        bundle_id: "BND-200"
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await scanBundle(req, res, next);

    expect(tx.bundleScanLog.create).toHaveBeenCalledWith({
      data: {
        bundleRecordId: 21,
        facultyId: 14,
        dutyId: 8
      }
    });
    expect(tx.activityLog.create).toHaveBeenCalledWith({
      data: {
        facultyId: 14,
        dutyId: 8,
        type: "BUNDLE_SCANNED",
        message: "Bundle BND-200 scanned for Physics in room A-101"
      },
      include: {
        faculty: {
          select: {
            name: true
          }
        }
      }
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      message: "Bundle scanned successfully",
      scan_log_id: 300,
      scanned_at: "2026-03-22T05:00:00.000Z",
      bundle: {
        bundle_id: "BND-200",
        exam_id: 55,
        subject: "Physics",
        room: "A-101"
      }
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("starts a washroom log with active status", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });
    prisma.washroomLog.findFirst.mockResolvedValue(null);

    const startTime = new Date();
    const tx = {
      washroomLog: {
        create: jest.fn().mockResolvedValue({
          id: 901,
          studentId: "STU-12",
          startTime,
          endTime: null,
          status: "ACTIVE"
        })
      },
      activityLog: {
        create: jest.fn().mockResolvedValue({})
      }
    };
    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        duty_id: 8,
        student_id: "STU-12"
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await startWashroomTimer(req, res, next);

    expect(tx.washroomLog.create).toHaveBeenCalledWith({
      data: {
        facultyId: 14,
        dutyId: 8,
        studentId: "STU-12",
        status: "ACTIVE"
      }
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      message: "Washroom timer started",
      washroom_log: {
        log_id: 901,
        student_id: "STU-12",
        start_time: startTime.toISOString(),
        end_time: null,
        duration_seconds: expect.any(Number),
        status: "ACTIVE",
        state: "green"
      }
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("ends a washroom log and marks a violation when duration exceeds the threshold", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });
    prisma.washroomLog.findFirst.mockResolvedValue({
      id: 901,
      studentId: "STU-12",
      startTime: new Date(Date.now() - 11 * 60 * 1000),
      endTime: null,
      status: "ACTIVE"
    });

    const tx = {
      washroomLog: {
        update: jest.fn().mockImplementation(async ({ data }) => ({
          id: 901,
          studentId: "STU-12",
          startTime: new Date(Date.now() - 11 * 60 * 1000),
          endTime: data.endTime,
          status: data.status
        }))
      },
      activityLog: {
        create: jest.fn().mockResolvedValue({})
      }
    };
    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        duty_id: 8,
        student_id: "STU-12"
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await endWashroomTimer(req, res, next);

    expect(tx.washroomLog.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 901 },
        data: expect.objectContaining({
          status: "VIOLATION"
        })
      })
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      message: "Washroom timer ended",
      washroom_log: expect.objectContaining({
        log_id: 901,
        student_id: "STU-12",
        status: "VIOLATION",
        state: "red"
      })
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("returns active washroom logs with computed status and duration", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });
    prisma.activityLog.findMany.mockResolvedValue([]);
    prisma.washroomLog.findMany.mockResolvedValue([
      {
        id: 901,
        studentId: "STU-12",
        startTime: new Date(Date.now() - 6 * 60 * 1000),
        endTime: null,
        status: "ACTIVE"
      }
    ]);
    prisma.sOSRequest.count.mockResolvedValue(2);
    prisma.seatingAllocation.count.mockResolvedValue(60);

    const req = {
      query: {
        duty_id: 8
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await getActivity(req, res, next);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      duty: {
        duty_id: 8,
        exam_id: 55,
        subject: "Physics",
        room: "A-101"
      },
      registered_count: 60,
      max_capacity: 60,
      pending_sos_count: 2,
      washroom_logs: [
        expect.objectContaining({
          log_id: 901,
          student_id: "STU-12",
          status: "WARNING",
          state: "yellow"
        })
      ],
      activities: []
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("requires the declaration checkbox for report submission", async () => {
    const req = {
      body: {
        duty_id: 8,
        total_students_present: 58,
        total_answer_sheets_collected: 58,
        no_incidents: true,
        declaration_accepted: false
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await submitReport(req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: "Declaration acceptance is required"
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("submits a post-exam report successfully", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });

    const createdAt = new Date("2026-03-22T05:00:00.000Z");
    const tx = {
      postExamReport: {
        create: jest.fn().mockResolvedValue({
          id: 71,
          facultyId: 14,
          dutyId: 8,
          totalStudentsPresent: 58,
          totalAnswerSheetsCollected: 58,
          noIncidents: false,
          incidentDetails: "One medical case handled.",
          remarks: "Collection verified.",
          declarationAccepted: true,
          createdAt
        })
      },
      activityLog: {
        create: jest.fn().mockResolvedValue({})
      }
    };

    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        duty_id: 8,
        total_students_present: 58,
        total_answer_sheets_collected: 58,
        no_incidents: false,
        incident_details: "One medical case handled.",
        remarks: "Collection verified.",
        declaration_accepted: true
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await submitReport(req, res, next);

    expect(tx.postExamReport.create).toHaveBeenCalledWith({
      data: {
        facultyId: 14,
        dutyId: 8,
        totalStudentsPresent: 58,
        totalAnswerSheetsCollected: 58,
        noIncidents: false,
        incidentDetails: "One medical case handled.",
        remarks: "Collection verified.",
        declarationAccepted: true
      }
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      message: "Post-exam report submitted successfully",
      report: {
        report_id: 71,
        duty_id: 8,
        total_students_present: 58,
        total_answer_sheets_collected: 58,
        no_incidents: false,
        incident_details: "One medical case handled.",
        remarks: "Collection verified.",
        declaration_accepted: true,
        created_at: "2026-03-22T05:00:00.000Z"
      }
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("creates an SOS request and returns the pending count", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 14 });
    prisma.duty.findFirst.mockResolvedValue({
      id: 8,
      facultyId: 14,
      room: "A-101",
      examId: 55,
      exam: {
        subject: "Physics"
      }
    });

    const createdAt = new Date("2026-03-22T05:00:00.000Z");
    const tx = {
      sOSRequest: {
        create: jest.fn().mockResolvedValue({
          id: 44,
          facultyId: 14,
          message: "URGENT_HELP",
          status: "PENDING",
          createdAt
        })
      },
      activityLog: {
        create: jest.fn().mockResolvedValue({})
      }
    };

    prisma.$transaction.mockImplementation(async (callback) => callback(tx));
    prisma.sOSRequest.count.mockResolvedValue(3);

    const req = {
      body: {
        duty_id: 8,
        message: "URGENT_HELP"
      },
      user: {
        user_id: 99,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await requestSOS(req, res, next);

    expect(tx.sOSRequest.create).toHaveBeenCalledWith({
      data: {
        facultyId: 14,
        message: "URGENT_HELP",
        status: "PENDING"
      }
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      message: "SOS request submitted",
      sos_request: {
        request_id: 44,
        faculty_id: 14,
        message: "URGENT_HELP",
        status: "PENDING",
        created_at: "2026-03-22T05:00:00.000Z"
      },
      pending_count: 3
    });
    expect(next).not.toHaveBeenCalled();
  });
});
