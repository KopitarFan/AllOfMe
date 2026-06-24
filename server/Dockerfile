# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-bookworm-slim AS toolchain
ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable \
  && corepack prepare pnpm@11.5.3 --activate

FROM toolchain AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

FROM deps AS build
COPY tsconfig.json tsconfig.build.json vitest.config.ts ./
COPY src ./src
RUN pnpm build

FROM toolchain AS prod-deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --prod --frozen-lockfile

FROM node:${NODE_VERSION}-bookworm-slim AS runtime
ARG SOURCE_URL="https://github.com/KopitarFan/AllOfMe"
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
ENV LOG_LEVEL=info
ENV CLOUD_SAVE_STORE=local
ENV CLOUD_SAVE_DATA_DIR=/app/data/cloud-saves
LABEL org.opencontainers.image.source="${SOURCE_URL}" \
  org.opencontainers.image.description="All Of Me Fastify cloud-save API"

WORKDIR /app

RUN mkdir -p /app/data/cloud-saves \
  && chown -R node:node /app

COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./

USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || '3000') + '/healthz').then((response) => { if (!response.ok) process.exit(1); }).catch(() => process.exit(1));"

CMD ["node", "dist/server.js"]
