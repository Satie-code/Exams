const express = require("express");

const { submitReport } = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.post("/", submitReport);

module.exports = router;
