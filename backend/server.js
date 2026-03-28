const app = require("./app");
const http = require("http");
const { initSocket } = require("./config/socket");

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

initSocket(server);

server.listen(PORT, () => {
  console.log(`EXAMS backend listening on port ${PORT}`);
});
