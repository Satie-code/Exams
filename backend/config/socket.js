const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");

let io;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST", "PATCH", "PUT", "DELETE"]
    }
  });

  io.use((socket, next) => {
    try {
      const authHeader = socket.handshake.auth?.token;
      if (!authHeader) {
        return next(new Error("Authentication error: No token provided"));
      }
      
      const token = authHeader.replace("Bearer ", "");
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      if (decoded.role !== "ADMIN") {
        return next(new Error("Unauthorized role: Only ADMIN can connect"));
      }

      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error("Authentication error: Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    socket.join("admin_room");
  });
};

const getIO = () => {
  if (!io) {
    throw new Error("Socket.io not initialized!");
  }
  return io;
};

module.exports = {
  initSocket,
  getIO
};
