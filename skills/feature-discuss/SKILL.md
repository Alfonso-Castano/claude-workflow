---
name: feature-discuss
description: Capture implementation decisions for a feature before planning begins — libraries, error handling, edge cases, scope boundary. First step of the full feature loop. Supports --thorough for a deeper brainstorm of the main design fork before decisions are captured.
disable-model-invocation: true
allowed-tools: Bash, Read, Write
---

<runtime_note>
Explicit-invocation only (`/feature-discuss`). Never auto-triggers. Accepts an optional `--thorough` flag.
</runtime_note>

<objective>

Capture *how* to build the feature, not just *what* to build, before any planning happens. Planning cannot start on solid ground until these decisions exist. Output is `.context/features/NNN-slug/CONTEXT.md`.

Shared conventions — directory layout, file ownership, task statuses, in-flight definition, feature numbering, branch and commit policy — live in `references/context-contract.md` in the `feature` skill's directory (installed at `~/.claude/skills/feature/references/context-contract.md`); follow it rather than re-deriving.

</objective>

<process>

## 1. Ground yourself

`OVERVIEW.md` and `STATE.md` are already in context — the project `CLAUDE.md`'s `@imports` load both at session start. Re-read them directly only if they changed during this session, or if the imports are missing (no `CLAUDE.md`, or it lacks the `@imports` line). Don't read `research/` or `DECISIONS.md` in full — unless the conversation surfaces a specific reason to check further. Keep this step cheap.

## 2. Scope check (borrowed from brainstorming's discipline)

Before asking anything else, ask yourself: does this request actually describe multiple independent features? (E.g., "add auth, billing, and an admin dashboard" is three features, not one.) If so, say this to the user directly and recommend running `/feature-discuss` separately for each, starting with the first. Don't spend the Q&A below refining a request that needs splitting first.

## 3. Deeper brainstorm — only with `--thorough`

**Skip this step entirely unless `--thorough` was passed.** Without the flag, go straight to step 4.

With the flag, read `~/.claude/skills/feature/references/thorough-brainstorm.md` and run its block (widen → narrow to 2–3 approaches → the user chooses) on the feature's main design fork, **before** the Q&A below — the approach chosen determines the smaller decisions. Follow that file's "Applied to `/feature-discuss`" section for scope and how to record the result.

## 4. Lightweight Q&A — assumptions mode by default

Propose your best guess at the implementation decisions, and ask the user to confirm or correct, rather than open-ended interviewing — this is faster in the common case where your guesses are reasonable. Cover, as relevant:

- Libraries / dependencies to use or avoid
- Error-handling strategy for this feature
- Whether behavior is scoped narrowly or applies globally
- Edge cases worth deciding now rather than leaving to the planner's judgment
- Anything from `STATE.md` or `OVERVIEW.md` that constrains the approach

Ask one question (or one batch of proposed assumptions) at a time. If the user says "just use your judgment" on something, note that explicitly in the output rather than silently picking — the planner should be able to tell "decided by user" from "Claude's default judgment call" at a glance.

If the user prefers a fuller interview instead of assumptions-mode for this feature, switch — don't insist on the faster mode against their stated preference.

**Push back on consequential choices.** When a choice that meaningfully shapes the feature looks driven by fear, avoidance, or convenience rather than reasoning, say so and press on the reasoning before accepting it — don't just validate and move on. If the user overrides something you recommended, ask what's behind it. Reserve this for decisions that matter; routine answers don't need a challenge.

## 5. Write CONTEXT.md

If this skill was invoked directly (no `/feature` router before it) and `feature/NNN-slug` doesn't exist yet as a branch, create it now and record the pre-branch HEAD as the Base SHA — the same thing `/feature`'s step 3 normally does ahead of this skill:

```bash
git rev-parse HEAD    # only if no feature branch exists yet — this is the Base SHA
git checkout -b feature/NNN-slug
mkdir -p .context/features/NNN-slug
```

```markdown
# Feature: <name>

**Base:** <starting commit SHA>

## Goal
[One sentence — what this feature does]

## Scope
[What's in scope. What's explicitly out of scope, if it came up.]

## Implementation Decisions
- [Decision]: [what was decided, and who decided it — user or Claude's default judgment]
- ...
- (`--thorough` only) [Chosen approach]: [what was chosen, decided by user] — rejected: [alternative] ([why it lost]), ...

## Global Constraints
[Project-wide conventions every task in this feature must respect — established patterns, style rules, invariants. This is what `prompt-engineer` restates verbatim to executor subagents that never see this file.]

## Open Questions
[Anything explicitly deferred to the planner or executor's judgment]
```

## 6. Hand off

Tell the user the next command is `/feature-plan`. Suggest `--thorough` whenever the feature introduces a dependency not already in the project's manifest, or is a first-in-this-repo integration (a new external service, protocol, or pattern this codebase hasn't used before) — either signals real research is needed before planning.

</process>
