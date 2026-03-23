jest.mock("../config/prisma", () => ({
  $transaction: jest.fn()
}));

const prisma = require("../config/prisma");
const { approveDutySwap } = require("../controllers/adminController");
const { createMockResponse } = require("./helpers/httpMocks");

describe("adminController.approveDutySwap", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("approves a pending swap and returns the updated status", async () => {
    const tx = {
      dutySwapRequest: {
        findUnique: jest.fn().mockResolvedValue({
          id: 9,
          status: "PENDING",
          requesterDutyId: 10,
          targetDutyId: 20,
          requesterDuty: {
            id: 10,
            facultyId: 100
          },
          targetDuty: {
            id: 20,
            facultyId: 200
          }
        }),
        update: jest.fn().mockResolvedValue({})
      },
      duty: {
        update: jest.fn().mockResolvedValue({})
      }
    };

    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    const req = {
      body: {
        swap_request_id: 9,
        approved: true
      },
      user: {
        user_id: 1,
        role: "ADMIN"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await approveDutySwap(req, res, next);

    expect(tx.duty.update).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        where: { id: 10 },
        data: {
          facultyId: 200,
          status: "CONFIRMED"
        }
      })
    );
    expect(tx.duty.update).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        where: { id: 20 },
        data: {
          facultyId: 100,
          status: "CONFIRMED"
        }
      })
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      message: "Duty swap approved successfully",
      swap_request_id: 9,
      status: "APPROVED"
    });
    expect(next).not.toHaveBeenCalled();
  });
});
