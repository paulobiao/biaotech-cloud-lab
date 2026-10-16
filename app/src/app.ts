import { createServer, type Server } from "node:http";

export const SERVICE = "biaotech-cloud-lab";

export interface AppState {
  ready: boolean;
}

export function createApp(state: AppState = { ready: true }): Server {
  const environment = process.env.APP_ENV ?? "local";
  const version = process.env.APP_VERSION ?? "0.0.0-dev";

  return createServer((req, res) => {
    const started = Date.now();
    const path = new URL(req.url ?? "/", "http://localhost").pathname;
    const base = (status: string) => ({
      service: SERVICE,
      status,
      environment,
      version,
      timestamp: new Date().toISOString(),
    });

    let code = 200;
    let body: Record<string, unknown>;

    if (req.method !== "GET" && req.method !== "HEAD") {
      code = 405;
      body = { ...base("error"), error: "method_not_allowed" };
    } else if (path === "/") {
      body = { ...base("ok"), name: "BiaoTech Cloud Lab", endpoints: ["/health", "/ready"] };
    } else if (path === "/health") {
      body = { ...base("healthy"), uptimeSeconds: Math.round(process.uptime()) };
    } else if (path === "/ready") {
      code = state.ready ? 200 : 503;
      body = base(state.ready ? "ready" : "not_ready");
    } else {
      code = 404;
      body = { ...base("error"), error: "not_found" };
    }

    res.writeHead(code, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    res.end(req.method === "HEAD" ? undefined : JSON.stringify(body));

    // One JSON line per request: stdout is shipped to CloudWatch Logs by the ECS awslogs driver.
    console.log(JSON.stringify({ level: "info", msg: "request", method: req.method, path, status: code, durationMs: Date.now() - started }));
  });
}
