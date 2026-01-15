FROM node:20-bookworm AS builder

WORKDIR /app/backend

COPY backend/package.json backend/pnpm-lock.yaml ./
COPY backend/patches ./patches

RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile

COPY backend/ ./
RUN mkdir -p dist
RUN pnpm bundle:esbuild


FROM node:20-bookworm-slim AS runtime

ENV NODE_ENV=production
ENV SUB_STORE_DATA_BASE_PATH=/data
ENV SUB_STORE_BACKEND_API_HOST=0.0.0.0
ENV SUB_STORE_BACKEND_API_PORT=3000

WORKDIR /app

RUN mkdir -p /data && chown -R node:node /data

COPY --from=builder --chown=node:node /app/backend/dist/sub-store.bundle.js ./sub-store.bundle.js

USER node

EXPOSE 3000

CMD ["node", "/app/sub-store.bundle.js"]
