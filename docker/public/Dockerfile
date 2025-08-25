# ---- Base: Node 20 on Debian (Python 3.11 available) ----
FROM node:20-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

# Minimal apt, no PPAs; Debian has Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev python3-pip \
      ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entire repository into the image (Railway builds from GitHub)
# Build context MUST be the repo root for this to work.
COPY . /app/traceroot

# Remove any enterprise ("ee") directories if present (optional)
RUN find /app/traceroot -type d -name "ee" -prune -exec rm -rf {} +

# ---- Python deps in a venv ----
WORKDIR /app/traceroot
RUN python3 -m venv venv \
 && . venv/bin/activate \
 && pip install --upgrade pip \
 && pip install .

# ---- Build the Next.js UI ----
WORKDIR /app/traceroot/ui

# If you have a lockfile, npm ci is faster & reproducible; otherwise fallback to npm i
# We'll attempt npm ci, and fallback to npm install if no lockfile exists.
RUN if [ -f package-lock.json ]; then npm ci --omit=dev=false; else npm install; fi

# Ensure your next.config.* is in place (with /api rewrite to localhost:8000)
RUN npm run build

# ---- Final runtime ----
# (Using same base to keep it simple; you could create a slimmer runtime stage if needed)
WORKDIR /app/traceroot
ENV PATH="/app/traceroot/venv/bin:${PATH}"

# ---- Runtime env defaults (override in Railway Variables) ----
ENV PORT=3000
ENV NEXT_PUBLIC_APP_URL="http://localhost:3000"
# UI will call FastAPI via Next.js rewrite on the same domain:
ENV NEXT_PUBLIC_REST_API_ENDPOINT="/api"
ENV NEXT_PUBLIC_AUTH_ENDPOINT="/api"
# Server-side internal API URL:
ENV REST_API_ENDPOINT="http://localhost:8000"

ENV REST_LOCAL_MODE=false
ENV NEXT_PUBLIC_LOCAL_MODE=false

# Optional/integrations (override as needed)
ENV JAEGER_URL=""
ENV DB_NAME=traceroot
ENV DB_CHAT_COLLECTION=agent_chat
ENV DB_CHAT_METADATA_COLLECTION=chat_metadata
ENV DB_CONNECTION_TOKENS_COLLECTION=connection_tokens
ENV DB_TRACEROOT_TOKENS_COLLECTION=traceroot_tokens
ENV DB_USER_NAME=traceroot
ENV DB_PASSWORD=""

# Expose both ports (Railway only publishes PORT)
EXPOSE 3000 8000

# Copy start script (path valid because build context is repo root)
COPY docker/public/start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
