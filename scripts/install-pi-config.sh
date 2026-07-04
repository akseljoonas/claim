#!/usr/bin/env bash
# Merge this repo's pi providers (pi/models.json) into ~/.pi/agent/models.json.
# Existing providers with other names are preserved; a .bak backup is written.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

node - "$REPO_DIR/pi/models.json" <<'EOF'
const fs = require("fs"), os = require("os"), path = require("path");
const src = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const dir = process.env.PI_CODING_AGENT_DIR || path.join(os.homedir(), ".pi", "agent");
fs.mkdirSync(dir, { recursive: true });
const dest = path.join(dir, "models.json");
let existing = {};
if (fs.existsSync(dest)) {
  fs.copyFileSync(dest, dest + ".bak");
  existing = JSON.parse(fs.readFileSync(dest, "utf8"));
}
existing.providers = { ...(existing.providers || {}), ...src.providers };
fs.writeFileSync(dest, JSON.stringify(existing, null, 2) + "\n");
console.log(`Merged providers [${Object.keys(src.providers).join(", ")}] into ${dest}`);
EOF
