const express = require("express");

const { requestSOS } = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.post("/", requestSOS);

module.exports = router;
