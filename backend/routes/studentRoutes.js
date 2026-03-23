const express = require("express");

const {
  getAssignedExams,
  getStudentSeating
} = require("../controllers/studentController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("STUDENT"));

router.get("/exams", getAssignedExams);
router.get("/seating", getStudentSeating);

module.exports = router;
