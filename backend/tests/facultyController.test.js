jest.mock("../config/prisma", () => ({
  faculty: {
    findUnique: jest.fn()
  },
  duty: {
    findMany: jest.fn(),
    findUnique: jest.fn()
  },
  dutySwapRequest: {
    findFirst: jest.fn()
  },
  $transaction: jest.fn()
}));

const prisma = require("../config/prisma");
const {
  getFacultyDuties,
  requestDutySwap
} = require("../controllers/facultyController");
const { createMockResponse } = require("./helpers/httpMocks");

describe("facultyController", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("returns only the authenticated faculty duties", async () => {
    prisma.faculty.findUnique.mockResolvedValue({ id: 12 });
    prisma.duty.findMany.mockResolvedValue([
      {
        id: 1,
        examId: 11,
        room: "A-101",
        role: "INVIGILATOR",
        status: "CONFIRMED",
        exam: {
          subject: "Mathematics",
          examDate: new Date("2026-04-10T00:00:00.000Z"),
          examTime: "09:00 AM"
        }
      }
    ]);

    const req = {
      user: {
        user_id: 50,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await getFacultyDuties(req, res, next);

    expect(prisma.duty.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          facultyId: 12
        }
      })
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      duties: [
        {
          duty_id: 1,
          exam_id: 11,
          subject: "Mathematics",
          date: "2026-04-10",
          time: "09:00 AM",
          room: "A-101",
          role: "INVIGILATOR",
          status: "CONFIRMED"
        }
      ]
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("rejects swap requests for duties not owned by the requester", async () => {
    prisma.duty.findMany.mockResolvedValue([
      {
        id: 3,
        facultyId: 77,
        status: "CONFIRMED",
        faculty: {
          userId: 999
        }
      },
      {
        id: 8,
        facultyId: 88,
        status: "CONFIRMED",
        faculty: {
          userId: 222
        }
      }
    ]);

    const req = {
      body: {
        requester_duty_id: 3,
        target_duty_id: 8
      },
      user: {
        user_id: 45,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await requestDutySwap(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({
      message: "You can only request swaps for your own duties"
    });
    expect(next).not.toHaveBeenCalled();
  });

  it("creates a pending swap request for valid duties", async () => {
    prisma.duty.findMany.mockResolvedValue([
      {
        id: 3,
        facultyId: 77,
        status: "CONFIRMED",
        faculty: {
          userId: 45
        }
      },
      {
        id: 8,
        facultyId: 88,
        status: "CONFIRMED",
        faculty: {
          userId: 222
        }
      }
    ]);
    prisma.dutySwapRequest.findFirst.mockResolvedValue(null);

    const tx = {
      duty: {
        update: jest.fn().mockResolvedValue({})
      },
      dutySwapRequest: {
        create: jest.fn().mockResolvedValue({
          id: 19,
          status: "PENDING"
        })
      }
    };

    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        requester_duty_id: 3,
        target_duty_id: 8
      },
      user: {
        user_id: 45,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await requestDutySwap(req, res, next);

    expect(tx.dutySwapRequest.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          requesterDutyId: 3,
          targetDutyId: 8,
          requestedByFacultyId: 77
        })
      })
    );
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      message: "Duty swap requested successfully",
      swap_request_id: 19,
      status: "PENDING",
      duties: [
        {
          duty_id: 3,
          status: "PENDING_SWAP"
        },
        {
          duty_id: 8,
          status: "PENDING_SWAP"
        }
      ]
    });
    expect(next).not.toHaveBeenCalled();
  });
});
