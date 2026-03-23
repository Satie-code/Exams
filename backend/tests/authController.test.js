jest.mock("../config/prisma", () => ({
  user: {
    findUnique: jest.fn(),
    create: jest.fn()
  }
}));

jest.mock("bcrypt", () => ({
  hash: jest.fn()
}));

const bcrypt = require("bcrypt");
const prisma = require("../config/prisma");

const { register } = require("../controllers/authController");
const { createMockResponse } = require("./helpers/httpMocks");

describe("authController.register", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("creates a linked faculty profile when registering a faculty user", async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    bcrypt.hash.mockResolvedValue("hashed-password");
    prisma.user.create.mockResolvedValue({
      id: 7,
      email: "faculty@exams.com",
      role: "FACULTY"
    });

    const req = {
      body: {
        email: "faculty@exams.com",
        password: "secret123",
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    await register(req, res, next);

    expect(prisma.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          role: "FACULTY",
          faculty: {
            create: {}
          }
        })
      })
    );
    expect(res.status).toHaveBeenCalledWith(201);
    expect(next).not.toHaveBeenCalled();
  });
});
