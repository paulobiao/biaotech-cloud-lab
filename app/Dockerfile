# syntax=docker/dockerfile:1

# ---- build: install dev deps from the lockfile and compile TypeScript ----
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci --no-audit --no-fund
COPY src ./src
RUN npm run build

# ---- runtime: compiled JS only; the app has zero runtime npm dependencies ----
FROM node:24-alpine AS runtime
ARG APP_VERSION=0.0.0-dev
ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=${APP_VERSION}
WORKDIR /app
# Files stay root-owned (read-only for the app user).
COPY --from=build /app/package.json ./
COPY --from=build /app/dist/src ./dist/src
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" >/dev/null || exit 1
CMD ["node", "dist/src/index.js"]
