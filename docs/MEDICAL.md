# Turning this stack into a medical AI agent platform

Research notes, July 2026. Not legal advice.

## Why gpt-oss for medical

From the official model card ([arXiv:2508.10925](https://arxiv.org/html/2508.10925v1)), HealthBench scores at high reasoning effort (physician-rubric-graded health conversations; 262 physicians, 5,000 cases):

| Benchmark | gpt-oss-120b | gpt-oss-20b | Reference |
|---|---|---|---|
| HealthBench | 57.6 | 42.5 | o3 ≈ 60, GPT-4o = 32 |
| HealthBench Hard | 30.0 | 10.8 | o3 ≈ 31.6 |
| HealthBench Consensus | 90.6 | 84.9 | — |

Implications for this repo:

- **gpt-oss-120b (the `sglang` provider) is the production medical model** — near-o3 on health at ~1/100th the serving cost, self-hostable.
- **gpt-oss-20b (the `local-llamacpp` provider) is a development proxy only** — it collapses on hard clinical cases (10.8 vs 30.0).
- **Run reasoning effort high** for medical work (pi thinking level `high` maps to it via `pi/models.json`): +4.6 HealthBench points over low.
- Caveats that shape the architecture: the model card states gpt-oss models *"do not replace a medical professional and are not intended for the diagnosis or treatment of disease"*; SimpleQA hallucination rates are high (78.2% for 120b, 91.4% for 20b) → **retrieval grounding and clinician sign-off are architecture requirements**.
- License: Apache 2.0, no medical-use restriction. Community medical LoRAs exist (e.g. adapters trained on `FreedomIntelligence/medical-o1-reasoning-SFT`); fine-tune only after prompting + RAG plateau.

## How pi becomes the medical agent

All stock pi mechanisms, mostly repo-committable — iterate by chatting with the agent and hardening what fails:

| Layer | Mechanism | Medical use |
|---|---|---|
| Persona & guardrails | `AGENTS.md` (repo root, auto-loaded) or `--system-prompt` | Clinical scope, mandatory disclaimers, "differentials not diagnoses", red-flag escalation rules |
| Clinical workflows | Skills in `.pi/skills/` ([agentskills.io](https://agentskills.io) standard, `/skill:name`) | SOAP notes, discharge summaries, med reconciliation, guideline lookups. pi can write its own skills — ask it. |
| Real capabilities | Extensions in `.pi/extensions/*.ts` (custom LLM-callable tools + event interception) | FHIR/EHR queries, RAG over guideline corpus, drug-interaction APIs, PubMed. Interception: block PHI-path tool calls, confirmation gates, audit logging (HIPAA 45 CFR 164.312(b)) |
| Platform embedding | `pi --mode rpc` or the SDK; sessions are JSONL | Web frontend drives pi sessions programmatically; session files double as audit/retention records |
| Model adaptation | LoRA/QLoRA fine-tune (OpenAI cookbook has a guide) | Last resort; a dental-assessment fine-tune won OpenAI's Open Model Hackathon |

## Deployment

### Railway — agent layer only (no GPUs exist there)

Railway has **no GPU instances** as of June 2026 (feature request open since March 2024; no announced plans). Consequences:

- CPU inference of 20b technically fits a Pro replica (24 vCPU / 24GB; model is 12GB) at an estimated 10–30 tok/s — wrong model + wrong speed for medical; don't.
- **Viable pattern:** platform + pi (RPC mode, `docker/agent/` image deploys as-is) on Railway; **inference via a HIPAA-BAA provider serving gpt-oss-120b**:
  - Groq — $0.15/$0.60 per M tokens, BAA available (raw inference only, built-in tools excluded from BAA scope)
  - Fireworks — SOC 2 Type II + HIPAA
  - Dedicated H100s: Modal (BAA on Enterprise), RunPod (BAAs executable; verify SOC 2 Type II status). Avoid Vast.ai for PHI (P2P marketplace, no BAA found).
  - Wiring = one more provider entry in `pi/models.json`; the model is still gpt-oss-120b, so nothing else changes.
- Railway mechanics: compose is not executed directly (each service → one Railway service; there is a compose import). Private networking is IPv6 — self-hosted servers there must bind `--host ::`. Healthchecks are HTTP, deploy-time only (`RAILWAY_HEALTHCHECK_TIMEOUT_SEC` for slow model loads). Volumes: 50GB+ on Pro, incompatible with replicas.
- Compliance: Railway is SOC 2 Type II; **HIPAA BAA available as a paid add-on** (unpublished spend minimum, team@railway.com); EU-West region for GDPR residency.
- PHI reality check: this path needs BAAs with both Railway and the inference provider — third parties are back in the PHI chain.

### On-premise — the PHI deployment (already built here)

`docker compose --profile gpu up` on a Linux box with 1×H100/H200 (~80GB VRAM) **is** the on-prem deployment: PHI never leaves the network, no model-vendor BAA exists because there is no model vendor. This is the model card's headline use case ("open models may be especially impactful in global health, where privacy and cost constraints can be important"). A 2025 cost-benefit analysis ([arXiv:2509.18101](https://arxiv.org/html/2509.18101v1)) puts self-hosted 120b within ~10% of commercial-API accuracy on ~$30k of hardware.

Still needed before production:

- Reverse proxy with TLS + authentication in front of SGLang (it ships with **zero auth**)
- Audit-log shipping (SGLang request logs + pi session JSONL)
- Pinned image tags (`SGLANG_TAG`), offline weight mirroring for air-gapped sites (`TIKTOKEN_ENCODINGS_BASE` + HF cache volume pre-seed)
- You own all HIPAA Security Rule obligations: encryption, access control, patching

### Recommended shape

On-prem (or private-colo H100) SGLang + gpt-oss-120b for everything touching PHI; Railway for the non-PHI web/orchestration tier, reaching inference over VPN/tunnel.

## Regulatory ceiling (headline facts)

- **HIPAA:** self-hosting removes the model-vendor BAA; infra providers hosting PHI still need one; you own Security Rule compliance.
- **EU AI Act / MDR:** an app with an *intended medical purpose* is a medical device under MDR 2017/745; class IIa+ ⇒ automatically **high-risk** under AI Act Annex I — data governance, human oversight, conformity assessment, post-market surveillance. Duties land on the deployer/manufacturer (~Aug 2026), not on OpenAI. gpt-oss itself is GPAI (obligations since Aug 2025).
- Practical consequence: frame the product as **clinician-assist with human sign-off**, not autonomous diagnosis, unless prepared for conformity assessment.
