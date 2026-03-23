const { allowRoles } = require("../middleware/authMiddleware");
const { createMockResponse } = require("./helpers/httpMocks");

describe("authMiddleware.allowRoles", () => {
  it("blocks access when the authenticated user does not have the required role", () => {
    const req = {
      user: {
        user_id: 11,
        role: "FACULTY"
      }
    };
    const res = createMockResponse();
    const next = jest.fn();

    allowRoles("ADMIN")(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({
      message: "Forbidden: insufficient permissions"
    });
    expect(next).not.toHaveBeenCalled();
  });
});
