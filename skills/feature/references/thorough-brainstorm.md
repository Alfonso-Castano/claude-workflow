# Thorough Brainstorm

Shared by `/init-project --thorough` and `/feature-discuss --thorough`. Read this file **only** when `--thorough` was passed — without the flag, neither skill touches it, so the default path costs nothing extra.

The skills' normal questioning is convergent: it extracts and confirms what the user already has in mind. This block is the opposite on purpose — it widens first, then narrows to real options, then the user chooses. Run it inline. Do not spawn subagents for it.

## The block

Run these three steps as **one compact message**, not three round-trips. Keep each part short — a wall of text defeats the point.

### 1. Widen

- **3–4 framings** of the problem or design question. They must differ in *kind* — a different way of solving it, a different scope, a different assumption about who or what it's for — not wording variations of one idea. If you can only find one real framing, say so and skip ahead; don't pad.
- **The strongest case against the user's current leaning**, in a short paragraph, made in good faith. Argue it as its best advocate would, not as a strawman.
- **A short pre-mortem:** "Six months from now this failed — the 2–3 most likely reasons." Specific to this idea, not generic project-failure boilerplate.

### 2. Narrow

Distil what you found into **2–3 concrete approaches**. For each:

- What it is, in a sentence or two
- Its real trade-off — what it buys and what it costs
- Which failure mode from the pre-mortem it is most and least exposed to

Then give a **stated recommendation and the reasoning for it**. Commit to a pick. "It depends" without a pick is not a recommendation.

### 3. The user chooses

The user picks, modifies, or rejects. Strategic choices belong to them — don't proceed on your own pick. Whatever they choose, record it (see the per-skill sections below) **with the alternatives that lost and why**, so a future session doesn't re-litigate it.

## Guardrails

- **Don't manufacture disagreement.** If the user's original idea really is the best approach, say so plainly and say why. Inventing alternatives to look thorough is as dishonest as rubber-stamping.
- **Mark what you can't verify.** If a trade-off claim depends on facts you haven't checked (a tool's current limits, pricing, what competitors do), label it *unverified* instead of stating it as fact. Point to the research step (`/init-project`) or `/feature-plan --thorough` as where it gets checked.
- **Pushback applies here too.** If the user's reaction to the options looks driven by fear, avoidance, or convenience rather than reasoning, name it and press on the reasoning before accepting the choice.
- **It's a discussion, not a form.** If the user's response opens a new thread, follow it. The block is a starting structure, not a script.

## Applied to `/init-project`

- **When:** after the normal questioning and scope check, before the "Ready to write it up?" decision gate. Enough of the idea has to be understood for the divergence to be useful.
- **Altitude:** the shape of the project — what it is, who it's for, how narrow or broad, which core value leads. **Not** tech stack: that stays with the research step, and asking about it early remains a questioning anti-pattern.
- **Tooling:** `AskUserQuestion` works well for step 3 (concrete options to react to). Use freeform text if the user signals they want to explain.
- **Recording:** the chosen approach goes into OVERVIEW.md (What This Is, Core Value, Scope — whichever it shapes) and as a row in Key Decisions. A `DECISIONS.md` seed entry records the chosen approach **and** the rejected alternatives with reasons. Only record what was actually chosen — no invented decisions.

## Applied to `/feature-discuss`

- **When:** before the assumptions-mode Q&A. The chosen approach determines the smaller decisions (libraries, error handling, edge cases), so it has to be settled first.
- **Altitude:** the feature's **main design fork** — the one or two choices that shape everything else. Not every decision; the minor ones still go through normal assumptions-mode afterward. If the feature has no real fork, say so in a line and move on.
- **Tooling:** plain-text options (this skill has no `AskUserQuestion`).
- **Recording:** the chosen approach goes under `Implementation Decisions` in CONTEXT.md, marked as decided by the user, with a one-line note per rejected alternative and why it lost. No template change.
