import { createApp } from "./app.js";

const port = Number(process.env.PORT ?? 3000);
const state = { ready: false };
const server = createApp(state);

server.listen(port, () => {
  state.ready = true;
  console.log(JSON.stringify({ level: "info", msg: "listening", port }));
});

// ECS sends SIGTERM before stopping a task: report not-ready, finish in-flight requests, exit.
function shutdown(signal: string) {
  state.ready = false;
  console.log(JSON.stringify({ level: "info", msg: "shutting down", signal }));
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
