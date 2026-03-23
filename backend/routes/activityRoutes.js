const express = require("express");

const { getActivity } = require("../controllers/dashboardController");
const { allowRoles, verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.use(verifyToken, allowRoles("FACULTY"));

router.get("/", getActivity);

module.exports = router;
