import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { after, before, test } from "node:test";
import { createApp, SERVICE } from "../src/app.js";

const state = { ready: true };
const server = createApp(state);
let baseUrl = "";

before(async () => {
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});
after(() => server.close());

async function get(path: string, method = "GET") {
  const res = await fetch(baseUrl + path, { method });
  return { status: res.status, body: (await res.json()) as Record<string, unknown> };
}

test("GET / identifies the service", async () => {
  const { status, body } = await get("/");
  assert.equal(status, 200);
  assert.equal(body.service, SERVICE);
  assert.equal(body.name, "BiaoTech Cloud Lab");
  for (const key of ["status", "environment", "version", "timestamp"]) assert.ok(key in body, key);
});

test("GET /health is healthy", async () => {
  const { status, body } = await get("/health");
  assert.equal(status, 200);
  assert.equal(body.status, "healthy");
});

test("GET /ready follows readiness state", async () => {
  assert.equal((await get("/ready")).status, 200);
  state.ready = false;
  const { status, body } = await get("/ready");
  state.ready = true;
  assert.equal(status, 503);
  assert.equal(body.status, "not_ready");
});

test("unknown path is 404, non-GET is 405", async () => {
  assert.equal((await get("/nope")).status, 404);
  assert.equal((await get("/", "POST")).status, 405);
});
