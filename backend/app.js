require("dotenv").config();

if (!process.env.JWT_SECRET) {
  console.error("FATAL ERROR: JWT_SECRET environment variable is not set.");
  process.exit(1);
}

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const activityRoutes = require("./routes/activityRoutes");
const adminRoutes = require("./routes/adminRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const authRoutes = require("./routes/authRoutes");
const bundleRoutes = require("./routes/bundleRoutes");
const facultyRoutes = require("./routes/facultyRoutes");
const reportRoutes = require("./routes/reportRoutes");
const sosRoutes = require("./routes/sosRoutes");
const studentRoutes = require("./routes/studentRoutes");
const supplyRoutes = require("./routes/supplyRoutes");
const washroomRoutes = require("./routes/washroomRoutes");

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());

// Global Rate Limiting
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // limit each IP to 200 requests per windowMs
  message: { message: "Too many requests from this IP, please try again later." },
  standardHeaders: true,
  legacyHeaders: false
});
app.use(globalLimiter);

app.use(express.json());

app.get("/health", (_req, res) => {
  res.status(200).json({ message: "EXAMS backend is running" });
});

app.use("/auth", authRoutes);
app.use("/student", studentRoutes);
app.use("/faculty", facultyRoutes);
app.use("/admin", adminRoutes);
app.use("/bundle", bundleRoutes);
app.use("/report", reportRoutes);
app.use("/sos", sosRoutes);
app.use("/attendance", attendanceRoutes);
app.use("/washroom", washroomRoutes);
app.use("/activity", activityRoutes);
app.use("/supplies", supplyRoutes);

app.use((req, res) => {
  res.status(404).json({
    message: `Route ${req.method} ${req.originalUrl} not found`
  });
});

app.use((err, _req, res, _next) => {
  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    message: err.message || "Internal server error"
  });
});

module.exports = app;
