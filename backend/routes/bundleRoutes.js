const express = require("express");

const { scanBundle } = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.post("/scan", scanBundle);

module.exports = router;
