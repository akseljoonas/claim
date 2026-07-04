# How the agent builds itself

You shape this agent **by talking to it**. This works because of one architectural fact:

> The agent has file-editing tools, and it sits in the folder that defines its own behavior. Its "personality" is not compiled into software — it is plain files in this repo. So when you tell it in chat to behave differently, it can edit those files itself. `/reload` applies the change instantly. Git records every self-modification so a human can review or undo it.

Three escalating levels, all creatable from chat:

| Level | Lives in | Language | Who drives it |
|---|---|---|---|
| **Rules** — what it must always/never do | `AGENTS.md` | plain English | medical person, alone |
| **Workflows** — reusable multi-step tasks (`/skill:name`) | `.pi/skills/` | plain English markdown | medical person, agent writes the file |
| **Tools** — new abilities (database lookups, EHR queries, citations) | `.pi/extensions/` | TypeScript | developer reviews, agent can draft |

## A real session (unedited, from this repo's history)

Everything below actually happened while building this repo, using the local dev model. It shows the honest version of the loop — including the part where the first attempt isn't enough.

### Teaching it a rule (3 iterations)

**Iteration 1.** The medical person types a new policy into the chat:

> *"New permanent policy from the medical team: whenever discussing any medication for a woman who could be pregnant or breastfeeding, you must first ask about pregnancy and breastfeeding status before giving medication information. Add this rule to your own working instructions in AGENTS.md."*

The agent edited its own `AGENTS.md` and added the rule. Test question: *"28-year-old woman with newly diagnosed hypertension — is lisinopril a good first choice?"* Result: it discussed pregnancy prominently, **but still answered first instead of asking**. Half-right.

**Iteration 2.** Tell it what went wrong, in plain English:

> *"Your pregnancy rule is too weak: you just answered a medication question about a 28-year-old woman directly, instead of first asking about pregnancy status. Replace that bullet so that when status is unknown, you ask FIRST and hold back medication recommendations."*

It sharpened its own rule. Retest: **still answered first.** Why? The rule was buried at the bottom of the list and contradicted a style rule ("lead with the answer"). Small models follow buried rules unreliably.

**Iteration 3.** Fix the structure, not just the wording:

> *"The rule is being ignored because it is buried and conflicts with 'lead with the answer'. Make the pregnancy bullet the FIRST hard rule, phrased as: respond ONLY with the question about her status — no medication content yet. And amend the style rule to apply only after hard rules are satisfied."*

The agent restructured its own rulebook. Retest — the complete response was:

> *"I'm not sure of her pregnancy or breastfeeding status. Could you let me know whether she is pregnant, trying to become pregnant, or breastfeeding?"*

Rule installed. Total time: three chat messages. Code written by humans: zero.

**Lessons the team should keep:**
- One pass is often not enough — *test after every rule change* (that's what [test-cases.md](test-cases.md) is for; this case is now #6 there).
- Rule *placement and conflicts* matter as much as wording. Put must-do-first rules at the top; check new rules against the Style section.
- The small dev model (20b) is the strict teacher: if a rule survives 20b, the production model (120b, much better at instruction-following) will handle it easily.

### Teaching it a workflow (1 message)

> *"The medical team wants a reusable workflow. Create a skill at `.pi/skills/triage-note/SKILL.md` … converting a free-text patient presentation into a structured triage note with exactly these sections: Chief complaint, History, Vitals (only if provided), Red flags, Suggested acuity (marked as suggestion requiring clinician confirmation), Missing information to gather."*

The agent wrote the skill file itself. Immediately after `/reload`, this works:

```
/skill:triage-note 67-year-old man, sudden severe headache 2 hours ago, worst of
his life, now drowsy with neck stiffness. BP 185/100, HR 58. On warfarin for AF.
```

…and returns a structured note with all six sections, red-flags including the anticoagulation risk, an urgent-acuity suggestion (subarachnoid hemorrhage suspicion), and missing-info including the INR. The skill is a file in the repo — versioned, reviewable, shared with the whole team on the next `git pull`.

## The safety net

Self-modification is safe here because every change is **a file diff in git**:

1. `git diff` shows exactly what the agent changed about itself — readable English, reviewable by anyone.
2. Nothing is permanent until a human commits it; `git checkout AGENTS.md` undoes a bad rule instantly.
3. [test-cases.md](test-cases.md) is the regression suite: after any change, re-run the list. A new rule that breaks an old behavior gets caught.
4. The agent only edits files in this project folder. The dockerized variant (`docker compose --profile local run agent-local`) adds a full container sandbox.

## Practical tips for the medical person

- Start requests with intent: *"New permanent policy…"* / *"From now on…"* signals the agent to edit `AGENTS.md` rather than just comply once. Being explicit — *"add this to your working instructions"* — always works.
- After the agent edits itself, type `/reload` in the chat (or restart `pi`) to load the change.
- One rule per message. Batched rules get half-applied.
- When behavior is wrong, quote what it did wrong in your correction — the agent uses that to write a sharper rule.
- Periodically ask the agent to *"review AGENTS.md for contradictions and redundancy"* — it's good at tidying its own rulebook.
