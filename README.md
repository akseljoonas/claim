# claim — a self-hosted medical AI agent

An AI assistant for clinical information work that runs **entirely on hardware you control**. No patient data ever leaves your machine or network — there is no OpenAI account, no cloud API, no third party seeing the conversation.

It is built from three open, swappable parts:

```
you chat with →  pi (the agent app)  →  gpt-oss (the medical brain)  →  your hardware
                 open source            open model by OpenAI,           your Mac today,
                                        strong on health benchmarks     a hospital server later
```

**Status: working today.** On a Mac it runs the smaller model (gpt-oss-20b) for development. The production setup (gpt-oss-120b — near-frontier on physician-graded health conversations, see [the research](docs/MEDICAL.md)) is ready in this repo and needs one GPU server to switch on.

## Why self-hosted for medical

- **Privacy is structural, not contractual.** With a cloud AI you sign agreements about patient data; here the data physically stays in the building. That's the difference that matters for HIPAA/GDPR.
- **The model is genuinely good at health.** gpt-oss-120b scores near OpenAI's o3 on HealthBench (physician-rubric-graded medical conversations) — and it's free to run, Apache-licensed, and yours.
- **It is not a doctor.** The model's own documentation says it "does not replace a medical professional and is not intended for the diagnosis or treatment of disease." Everything we build keeps a clinician in the loop. Details and limits: [docs/MEDICAL.md](docs/MEDICAL.md).

## Try it (10 minutes if the model is already downloaded)

Someone technical runs, on a Mac in this folder:

```bash
scripts/install-pi-config.sh   # one-time: register the local models
scripts/serve-local.sh         # starts the model server (first run downloads ~12GB)
pi                             # opens the chat — that's the agent
```

Then **anyone** can sit down and chat. Try: *"55-year-old on lisinopril reports a persistent dry cough — what should I consider?"* — and watch it follow the rules written in `AGENTS.md`.

## How this becomes *your* medical agent

The core idea: **the agent's medical behavior lives in [`AGENTS.md`](AGENTS.md) — a plain-English rulebook, no code.** The agent reads it at every start. The medical person owns that file.

The working loop for the medical person:

1. **Chat** with the agent about realistic cases
2. **Spot** something wrong — tone, missing caveat, overconfidence, wrong escalation
3. **Edit `AGENTS.md`** — add or sharpen a rule, in plain English
4. Type `/reload` in the chat and try the case again

That loop, repeated, is the product taking shape. No programming involved.

## The build plan

| Phase | What | Who | Done when |
|---|---|---|---|
| **0. Run it** | Get the quickstart working on one Mac, everyone has a first chat | developer | Whole team has talked to the agent |
| **1. Teach it the rules** | Iterate `AGENTS.md` via the loop above; collect every tried case + expected behavior into `docs/test-cases.md` | **medical person** (leads) | ~30–50 test cases the agent handles acceptably |
| **2. Encode workflows** | Turn recurring tasks (SOAP note drafting, discharge summaries, triage checklists, med reconciliation) into reusable "skills" — these are also plain-English markdown files (`.pi/skills/`); the medical person writes the checklist, a developer wires it in | medical person + developer | Each workflow invocable as `/skill:name` |
| **3. Ground it in real sources** | Connect trusted references so answers cite rather than recall: your guideline documents, a drug-interaction database, PubMed lookup. This kills most hallucination risk. Built as pi "extensions" (TypeScript) | developer | Answers to test cases carry citations from your sources |
| **4. Production** | Upgrade the brain to gpt-oss-120b on a GPU server (config already in this repo — `docker compose --profile gpu up`), on-premise for anything touching patient data; add login + encryption in front; compliance review (BAAs, EU AI Act/MDR classification) | developer + compliance | Pilot with real users on the 120b model |

Deployment options, costs, HIPAA/EU-AI-Act facts, and why on-premise beats cloud hosting for the patient-data path: **[docs/MEDICAL.md](docs/MEDICAL.md)**.

## Ground rules during development

- **No real patient data** in the system before Phase 4 infrastructure and sign-offs. Use realistic but invented cases.
- The agent's answers are drafts for professional review — never patient-facing without a clinician's sign-off. This framing also keeps the project on the right side of medical-device regulation (see [docs/MEDICAL.md](docs/MEDICAL.md)).

## For developers

Architecture, both deployment targets (Mac dev / GPU production), Docker usage, and all configuration: **[docs/SETUP.md](docs/SETUP.md)**.
