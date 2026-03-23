const jwt = require("jsonwebtoken");

const getJwtSecret = () => {
  if (!process.env.JWT_SECRET) {
    return null;
  }

  return process.env.JWT_SECRET;
};

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      message: "Authorization token is required"
    });
  }

  const token = authHeader.split(" ")[1];
  const jwtSecret = getJwtSecret();

  if (!jwtSecret) {
    return res.status(500).json({
      message: "JWT_SECRET is not configured"
    });
  }

  try {
    const decoded = jwt.verify(token, jwtSecret);

    req.user = {
      user_id: decoded.user_id,
      role: decoded.role
    };

    return next();
  } catch (_error) {
    return res.status(401).json({
      message: "Invalid or expired token"
    });
  }
};

const allowRoles = (...roles) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      message: "Unauthorized"
    });
  }

  if (!roles.includes(req.user.role)) {
    return res.status(403).json({
      message: "Forbidden: insufficient permissions"
    });
  }

  return next();
};

module.exports = {
  verifyToken,
  allowRoles
};
