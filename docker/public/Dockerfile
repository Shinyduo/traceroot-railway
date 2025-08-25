# ---- Base with Node 20 on Debian bookworm (Python 3.11 available) ----
FROM node:20-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

# Minimal apt; no PPAs, use Debian's Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
      python3-venv \
      python3-dev \
      python3-pip \
      curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy repo (Railway will build from your GitHub)
COPY . /app/traceroot

# Remove any EE folders
RUN find /app/traceroot -type d -name "ee" -prune -exec rm -rf {} +

# ---- Build Python deps in a venv ----
WORKDIR /app/traceroot
RUN python3 -m venv venv \
 && . venv/bin/activate \
 && pip install --upgrade pip \
 && pip install .

# ---- Build the Next.js UI ----
WORKDIR /app/traceroot/ui
# If you have a package-lock.json, this will leverage caching better:
# COPY traceroot/ui/package*.json ./
# RUN npm ci
RUN npm install
RUN npm run build

# ---- Runtime image ----
# (You can stay on the same image to keep it simple)
WORKDIR /app/traceroot
ENV PATH="/app/traceroot/venv/bin:${PATH}"

# Required env (tune in Railway)
ENV PORT=3000
ENV NEXT_PUBLIC_APP_URL="http://localhost:3000"
ENV REST_API_ENDPOINT="http://localhost:8000"
ENV NEXT_PUBLIC_REST_API_ENDPOINT="/api"
ENV REST_LOCAL_MODE=false
ENV NEXT_PUBLIC_LOCAL_MODE=false
ENV JAEGER_URL=""
ENV DB_NAME=traceroot
ENV DB_CHAT_COLLECTION=agent_chat
ENV DB_CHAT_METADATA_COLLECTION=chat_metadata
ENV DB_CONNECTION_TOKENS_COLLECTION=connection_tokens
ENV DB_TRACEROOT_TOKENS_COLLECTION=traceroot_tokens
ENV DB_USER_NAME=traceroot
ENV DB_PASSWORD=""

# Expose both ports (Railway will publish only PORT)
EXPOSE 3000 8000

# Add your start script
COPY docker/public/start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
