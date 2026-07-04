# claim — local gpt-oss + pi agent

A [pi](https://pi.dev) coding agent backed by locally-served [gpt-oss](https://huggingface.co/openai/gpt-oss-120b) models, with two inference targets:

| Target | Model | Server | Where it runs |
|---|---|---|---|
| `local-llamacpp` | gpt-oss-20b (MXFP4, ~13GB) | llama.cpp (Metal) | This Mac, natively |
| `sglang` | gpt-oss-120b (MXFP4, ~63GB) | SGLang (CUDA) | Linux box with ≥80GB NVIDIA VRAM, via Docker |

Both expose an OpenAI-compatible `/v1` API; pi is configured against both via `pi/models.json`, so switching is just `--provider`/`/model`.

> Why two targets: SGLang has no Apple Silicon backend and gpt-oss-120b doesn't fit in 32GB unified memory. gpt-oss-20b runs great on an M-series Mac; the 120b compose stack is ready for the day this points at a GPU machine.

## Quickstart (Mac, right now)

```bash
# 1. Register the providers with pi (merges into ~/.pi/agent/models.json, keeps a .bak)
scripts/install-pi-config.sh

# 2. Serve gpt-oss-20b (installs llama.cpp via brew if needed; downloads ~12GB once)
scripts/serve-local.sh

# 3. In another terminal — run the agent
pi --provider local-llamacpp --model gpt-oss-20b
# or auto-detect hardware:
scripts/agent.sh
```

This repo's `.pi/settings.json` also sets `local-llamacpp`/`gpt-oss-20b` as the default, so a plain `pi` in this directory works after step 1–2.

## Chatting with the agent

`llama-server` must be running first (`scripts/serve-local.sh` — instant once weights are cached; `scripts/agent.sh` checks this for you and picks the right backend).

```bash
pi                                  # interactive TUI (in this repo)
pi -p "explain compose.yaml"        # one-shot / headless
docker compose --profile local run --rm agent-local   # sandboxed TUI, repo at /workspace
```

In the TUI: type to chat, `@` fuzzy-references files, `!cmd` runs shell commands, `/model` switches models, Ctrl+C twice quits. First run in a directory asks you to trust its `.pi/settings.json`.

## GPU box (gpt-oss-120b via SGLang)

```bash
cp .env.example .env   # set SGLANG_TP (1 for a single H100/H200, 4 for 4x smaller cards)
docker compose --profile gpu up -d sglang        # first start downloads ~63GB
docker compose --profile gpu run --rm agent      # pi against gpt-oss-120b
```

Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). SGLang serves OpenAI-compatible endpoints on `:30000` (`/v1/chat/completions`, `/v1/responses`, `/health`) with the gpt-oss harmony reasoning/tool-call parsers enabled.

## Dockerized agent on the Mac (optional)

Runs pi in a container while llama.cpp serves natively on the host (Docker on macOS has no GPU access, so the model server stays on the host):

```bash
scripts/serve-local.sh                               # host terminal
docker compose --profile local run --rm agent-local  # containerized pi
```

## Layout

```
compose.yaml                  # sglang + agent (profile: gpu), agent-local (profile: local)
docker/agent/                 # pi agent image; config baked via PI_CODING_AGENT_DIR
  Dockerfile                  # two config dirs: /opt/pi-config-{sglang,local}
  models.docker.json          # same providers, container-network baseUrls
  settings.sglang.json        # default provider for the gpu profile
  settings.local.json         # default provider for the local profile
pi/models.json                # source of truth for pi providers (host baseUrls)
.pi/settings.json             # repo-level default provider/model for pi
scripts/
  serve-local.sh              # llama.cpp + gpt-oss-20b on the Mac
  install-pi-config.sh        # merge pi/models.json into ~/.pi/agent/models.json
  agent.sh                    # hardware auto-detect: sglang on NVIDIA, llama.cpp otherwise
.env.example                  # SGLANG_TAG/TP/PORT, LLAMA_PORT/CTX, WORKSPACE
```

## Medical AI platform

See [docs/MEDICAL.md](docs/MEDICAL.md) for how this stack extends into a medical agent platform (gpt-oss HealthBench results, pi customization layers, Railway vs on-premise deployment, HIPAA/EU-AI-Act headlines).

## Notes

- No API keys anywhere: gpt-oss weights are ungated (Apache 2.0) and both servers ignore auth; pi requires *some* `apiKey` value for custom providers, so a placeholder is set.
- gpt-oss sampling guidance (from OpenAI): temperature 1.0, top_p 1.0, no repetition penalties. Reasoning effort maps to pi thinking levels (`low/medium/high`) on the SGLang provider; llama.cpp runs at the model default (medium).
- Pin `SGLANG_TAG` to a release (e.g. `v0.5.12`) for reproducible deploys.
- pi package: `@earendil-works/pi-coding-agent` (needs node ≥ 22.19).
- Each compose agent service selects its provider via `PI_CODING_AGENT_DIR` (baked settings), not `command:` args — so `docker compose run agent-local <your args>` keeps the right model.
