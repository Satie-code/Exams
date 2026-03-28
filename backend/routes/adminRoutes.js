const express = require("express");

const { approveDutySwap, getDashboard, resolveSOS } = require("../controllers/adminController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("ADMIN"));

router.get("/dashboard", getDashboard);
router.patch("/swap/approve", approveDutySwap);
router.patch("/sos/:id/resolve", resolveSOS);

module.exports = router;
