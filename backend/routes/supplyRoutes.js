const express = require("express");

const { requestSupplies } = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.post("/request", requestSupplies);

module.exports = router;
