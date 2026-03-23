const express = require("express");

const {
  getFacultyDuties,
  getDutySwapOptions,
  requestDutySwap
} = require("../controllers/facultyController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.get("/duties", getFacultyDuties);
router.get("/duty/swap-options", getDutySwapOptions);
router.post("/duty/swap", requestDutySwap);

module.exports = router;
