# pi coding agent (pi.dev) preconfigured for local gpt-oss endpoints.
# Based on the official pi containerization docs (docs/containerization.md).
FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl git ripgrep \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Two baked config dirs — compose selects one via PI_CODING_AGENT_DIR, so the
# provider choice survives `docker compose run agent <args>` (which replaces
# the command). Sessions persist separately via PI_CODING_AGENT_SESSION_DIR.
ENV PI_CODING_AGENT_DIR=/opt/pi-config-sglang \
    PI_CODING_AGENT_SESSION_DIR=/root/.pi-sessions \
    PI_SKIP_VERSION_CHECK=1

COPY models.docker.json /opt/pi-config-sglang/models.json
COPY settings.sglang.json /opt/pi-config-sglang/settings.json
COPY models.docker.json /opt/pi-config-local/models.json
COPY settings.local.json /opt/pi-config-local/settings.json

WORKDIR /workspace
ENTRYPOINT ["pi"]
