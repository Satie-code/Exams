const express = require("express");

const { approveDutySwap } = require("../controllers/adminController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("ADMIN"));

router.patch("/swap/approve", approveDutySwap);

module.exports = router;
