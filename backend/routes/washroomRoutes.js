const express = require("express");

const {
  endWashroomTimer,
  startWashroomTimer
} = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.post("/start", startWashroomTimer);
router.post("/end", endWashroomTimer);

module.exports = router;
