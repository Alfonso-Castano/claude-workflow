---
name: init-project
description: Initialize a new project from a rough idea. Deep interrogation, optional domain research, and a roadmap if needed — writes durable context to .context/ that every future session and skill reads from. One-time, whole-project setup — not for individual features within an already-initialized project. Supports --thorough for a deeper brainstorm of the project's shape before it is written up.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Agent, AskUserQuestion
---

<runtime_note>
This skill is explicit-invocation only (`/init-project`). It never auto-triggers — `disable-model-invocation: true` in the frontmatter enforces that. This is deliberate: initialization is a one-time, deliberate action, not something that should fire on an ambiguous "I have an idea for..." remark.

Accepts an optional `--thorough` flag, which adds a deeper brainstorm to Step 2. Without it, the skill runs exactly as described below.
</runtime_note>

<objective>

Turn a rough, messy idea into a well-interrogated, optionally-researched, structured project foundation that any future Claude session — with zero prior context — can read and build on correctly.

**Creates:**
- `.context/OVERVIEW.md` — always
- `.context/research/` — only if research is accepted
- `.context/ROADMAP.md` — only if the project actually needs phases
- `.context/DECISIONS.md` — always (may be a thin seed if nothing beyond scope was decided)
- `.context/STATE.md` — always

**After this command:** the project has a durable foundation. Whatever handles individual features or phases later reads `.context/` — that is a separate, recurring process, not this skill's job.

</objective>

<execution_context>
This skill directory bundles:
- `references/questioning.md` — interrogation philosophy and technique (includes the scope check)
- `references/spec-review.md` — the fresh-context self-review step
- `templates/overview.md`, `templates/roadmap.md`, `templates/decisions.md`, `templates/state.md` — output file templates

Only with `--thorough`, also read `~/.claude/skills/feature/references/thorough-brainstorm.md` (shared with `/feature-discuss`).

Subagents used (defined in `~/.claude/agents/`): `context-researcher`, `context-research-synthesizer`, `context-roadmapper`.
</execution_context>

<process>

## 1. Setup Check

```bash
if [ -f .context/OVERVIEW.md ]; then
  echo "ALREADY_INITIALIZED"
fi
```

If already initialized: tell the user `.context/OVERVIEW.md` already exists, and stop. Don't overwrite silently. If they want to start over, that's their call to make explicitly (delete the directory themselves), not this skill's to infer.

## 2. Deep Questioning

Follow `references/questioning.md` in full — the philosophy, the freeform rule, the scope check, and the decision gate. This is the highest-leverage part of the whole flow; don't rush it.

Open with, inline and freeform (NOT AskUserQuestion): **"What do you want to build?"**

Follow the thread from there. Loop until the reference file's decision gate is accepted.

**With `--thorough`:** once you understand the idea well enough to write the overview, but **before** offering the decision gate, run the block from `thorough-brainstorm.md` (widen → narrow to 2–3 approaches → the user chooses) on the project's shape, following its "Applied to `/init-project`" section. If the user's choice reopens the idea, keep questioning; offer the decision gate only once the chosen approach is settled. Without the flag, skip this entirely.

## 3. Write OVERVIEW.md

Synthesize the conversation into `.context/OVERVIEW.md` using `templates/overview.md`. Do not compress — capture what was actually said, in the user's language.

```bash
mkdir -p .context
```

## 4. Offer Research

Use AskUserQuestion:
- header: "Research"
- question: "Research the domain before writing the roadmap?"
- options:
  - "Yes" — Investigate stack, features, architecture, and pitfalls
  - "No" — Skip — I know this domain well enough

**If "Yes":**

Tell the user this runs in the background and takes a few minutes: *"Spawning 4 researchers in parallel — no output until they return."*

Spawn 4 `context-researcher` agents in parallel, one per dimension, each with the project domain, project context from OVERVIEW.md, and its assigned dimension + question:

- Stack — "What's the standard, current stack for this kind of project?"
- Features — "What do products/projects like this typically include? Table stakes vs. differentiators vs. anti-features?"
- Architecture — "How are these typically structured? Major components and boundaries?"
- Pitfalls — "What do people commonly get wrong building this kind of thing?"

After all 4 complete, spawn one `context-research-synthesizer` to read all 4 files and write `.context/research/SUMMARY.md`.

Present the key findings from SUMMARY.md briefly before continuing.

**If "No":** skip to Step 5. No `.context/research/` directory is created.

## 5. Roadmap Decision

Spawn one `context-roadmapper` agent with `.context/OVERVIEW.md` and `.context/research/SUMMARY.md` (if it exists).

**If it returns `NO ROADMAP NEEDED`:** tell the user why in one line, and continue — no `.context/ROADMAP.md` is created. This is a valid, expected outcome for simple projects, not a fallback.

**If it returns `ROADMAP CREATED`:** continue to Step 6.

## 6. Present the Roadmap

Present it in sections scaled to complexity, not as one wall of text — introduce the overview, then walk through phases in digestible groups, checking in as you go rather than dumping the whole file and asking "does this look right?" once at the end.

Use AskUserQuestion after presenting:
- header: "Roadmap"
- question: "Does this phase structure work?"
- options:
  - "Yes, looks right" — Continue
  - "Adjust" — Tell me what to change

**If "Adjust":** get their notes, re-spawn `context-roadmapper` with the revision context, present again. Loop until accepted.

## 7. Write DECISIONS.md and STATE.md

Using `templates/decisions.md`: seed with whatever decisions actually came up during questioning (technical preferences stated unprompted, explicit exclusions with reasoning). An empty or near-empty seed is fine and correct if nothing beyond scope was actually decided.

If `--thorough` ran, include an entry for the chosen approach that also records the alternatives that were rejected and why (see `thorough-brainstorm.md`). Only record what the user actually chose.

Using `templates/state.md`: write Current Position and Next Action. Next Action should name Phase 1 if a roadmap exists, or the core value from OVERVIEW.md if it doesn't.

## 8. Spec Self-Review

Follow `references/spec-review.md`. Dispatch the fresh-context reviewer, handle its return (fix inline if issues found — don't re-run the whole writing step for minor fixes).

## 9. Done

If the project is a git repository, commit the new context once before
presenting the summary: `git add .context && git commit -m "chore(context): initialize project context"`.

Present a short completion summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PROJECT INITIALIZED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[Project Name]**

| File | Location |
|------|----------|
| Overview | .context/OVERVIEW.md |
| Research | .context/research/ (if run) |
| Roadmap | .context/ROADMAP.md (if applicable) |
| Decisions | .context/DECISIONS.md |
| State | .context/STATE.md |
```

No handoff to another skill. This is a terminal step — whatever handles the project's actual work picks up `.context/` in a later, separate session.

</process>

<success_criteria>

- [ ] `.context/` did not already exist, or the user was told and the flow stopped
- [ ] Questioning followed threads, wasn't rushed, included the scope check
- [ ] OVERVIEW.md captures full context in the user's language, not compressed
- [ ] Research offered and, if accepted, all 4 dimensions covered + synthesized
- [ ] Roadmap decision was an actual decision (NO ROADMAP NEEDED is a valid, expected outcome), not a default
- [ ] If a roadmap was created, it was presented in scaled sections with a real approval gate, not dumped as one block
- [ ] DECISIONS.md and STATE.md written, accurately reflecting what actually happened (no invented decisions)
- [ ] Fresh-context spec review ran and any real issues were fixed
- [ ] User knows the flow is complete and what's in `.context/`

</success_criteria>
