# Installing /init-project

Repo: https://github.com/Alfonso-Castano/claude-init-project

## Foundational CLAUDE.md

[`CLAUDE.md`](CLAUDE.md) in the repo root is a project-agnostic template, not something this repo installs. Copy it into any new project's root, run `/init-project` if `.context/` doesn't exist yet, and fill in the bracketed placeholders (project name/tagline at the top, and the Architecture Quick Reference section at the bottom).

## Quick install

This repo has three independently-installable pieces: **`/init-project`** (one-time project setup), **`/update-context`** (ongoing `.context/` maintenance), and **`feature-workflow`** (the recurring feature build loop — `/feature`, `/feature-quick`, `/feature-discuss`, `/feature-plan`, `/feature-execute`, `/feature-verify`). Install any one alone, or all together — `install.sh` takes an optional component argument.

**`/init-project` only** (default — no argument needed):

```bash
curl -fsSL https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash
```
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash
```

**`/update-context` only:**

```bash
curl -fsSL https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- context-update
```
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- context-update
```

**`feature-workflow` only:**

```bash
curl -fsSL https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- feature-workflow
```
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- feature-workflow
```

**All three:**

```bash
curl -fsSL https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- all
```
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/Alfonso-Castano/claude-init-project/main/install.sh | bash -s -- all
```

Each installs its own skill/agent files to `~/.claude/` in one step. Details on what gets installed and how below.

Two things to install, both at the **user level** (`~/.claude/`) so this works identically in every project, per the consistency requirement.

## 0. Push this folder to the repo (one-time)

From this folder:

```bash
git init
git add .
git commit -m "init-project skill: initial version"
git branch -M main
git remote add origin https://github.com/Alfonso-Castano/claude-init-project.git
git push -u origin main
```

## 1. The skill

Copy the whole `skills/init-project/` folder to:

```
~/.claude/skills/init-project/
```

Result:
```
~/.claude/skills/init-project/
  SKILL.md
  references/
    questioning.md
    spec-review.md
  templates/
    overview.md
    roadmap.md
    decisions.md
    state.md
```

For `/init-project --thorough` (optional deeper brainstorm), also copy `skills/feature/references/thorough-brainstorm.md` to `~/.claude/skills/feature/references/thorough-brainstorm.md`. `install.sh` does this automatically.

## 2. The subagents

Copy the three files from `agents/` to:

```
~/.claude/agents/context-researcher.md
~/.claude/agents/context-research-synthesizer.md
~/.claude/agents/context-roadmapper.md
```

## 3. /update-context (optional, separate from /init-project)

`/update-context` keeps an existing `.context/` directory (STATE.md,
DECISIONS.md, ROADMAP.md) current as work progresses — it's a different,
recurring capability from `/init-project`'s one-time setup, and installs
independently of it (see [Quick install](#quick-install) above for the
`context-update`-only one-liner).

**The skill:**

```
~/.claude/skills/update-context/SKILL.md
```

**The subagent** (does the actual read/write work, in its own isolated context):

```
~/.claude/agents/context-updater.md
```

**The staleness-check hook** (monitoring-only — never writes, never invokes Claude, just prints a reminder to stderr at session start if `.context/STATE.md` looks stale):

```
~/.claude/hooks/context-staleness-check.sh
```

The hook needs to be registered in `~/.claude/settings.json` under
`hooks.SessionStart` — `install.sh` does this automatically (merging into
any existing settings.json without disturbing other hooks or settings). If
installing by hand, add:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/context-staleness-check.sh" }
        ]
      }
    ]
  }
}
```

## 4. /feature-workflow (the one-big-feature loop)

The recurring loop for building a feature within an already-initialized project (`.context/` must already exist — run `/init-project` first if it doesn't). Installs independently of `/init-project` and `/update-context` (see [Quick install](#quick-install) above for the `feature-workflow`-only one-liner), but assumes `.context/OVERVIEW.md` and `.context/STATE.md` exist and are readable.

**The skills** (each triggers only on explicit invocation — `disable-model-invocation: true`, matching `/init-project` and `/update-context`):

```
~/.claude/skills/feature/SKILL.md            → /feature          (router — classifies size, reports in-flight status)
~/.claude/skills/feature-quick/SKILL.md      → /feature-quick    (fast path for small tasks)
~/.claude/skills/feature-discuss/SKILL.md    → /feature-discuss  (capture implementation decisions)
~/.claude/skills/feature-plan/SKILL.md       → /feature-plan     (research + decompose into task files)
~/.claude/skills/feature-execute/SKILL.md    → /feature-execute  (run tasks, one fresh subagent each)
~/.claude/skills/feature-verify/SKILL.md     → /feature-verify   (merged review + evidence gate)
```

**Two supporting skills, also installed by this component** (they're dependencies of the workflow above, not features on their own — `orchestrator` decides how to parallelize, `prompt-engineer` generates the actual dispatch prompts):

```
~/.claude/skills/orchestrator/SKILL.md
~/.claude/skills/prompt-engineer/SKILL.md
```

**The subagents** (each runs in its own fresh context window — this is the anti-context-rot mechanism the whole workflow is built around):

```
~/.claude/agents/feature-planner.md
~/.claude/agents/feature-executor.md
~/.claude/agents/feature-reviewer.md
```

### Using it

In a project that already has `.context/` (from `/init-project`):

```
/feature
```

Tell it what you want to build. It classifies the request:

- **Small, well-understood, one or a few files** → routes to `/feature-quick`: does the work, writes one task file for the record, still requires fresh verification evidence before claiming done. No discuss/plan/verify ceremony.
- **Everything else** → routes to the full loop: `/feature-discuss` → `/feature-plan` → `/feature-execute` → `/feature-verify`, run one at a time, in that order. Each writes its output to `.context/features/NNN-slug/` and tells you the next command.

You can also invoke any of these directly if you already know which stage you're at (e.g. `/feature-plan --thorough` if you know a feature touches unfamiliar territory and want a fuller research pass before decomposition).

`/feature-discuss --thorough` and `/init-project --thorough` opt in to a deeper brainstorm: widen the problem (distinct framings, the strongest case against your current leaning, a short pre-mortem), narrow to 2–3 approaches with a recommendation, and you choose. The chosen approach and the rejected alternatives are recorded. It's inline and adds no subagents, but it does add a round of discussion, so leave it off for simple work — without the flag both skills run as before. The shared logic lives in `skills/feature/references/thorough-brainstorm.md`.

### What it produces

```
.context/features/NNN-slug/
  CONTEXT.md      # from /feature-discuss — decisions, scope
  RESEARCH.md      # from /feature-plan — only if research happened
  tasks/
    001-*.md        # one file per task, never a monolithic plan
    ...
  REVIEW.md        # from /feature-verify — merged review + evidence
```

No `config.json` for this component — model-tier routing is decided per-task by the planner and read directly off each task file by `prompt-engineer`, rather than a separate project-level config file, matching the minimal-scaffolding precedent set by `/init-project`.

After a feature passes `/feature-verify`, it suggests merging the feature branch back to main, then spawns the `context-updater` subagent directly as an announced final step to refresh `.context/`. No context write ever happens from an ambient trigger — only as part of a command the user explicitly ran, and `/feature-verify` is such a command.

## Installing on any machine, going forward

Once step 0 is pushed, you never need these local files again. On any machine, in any Claude Code session (terminal or IDE), just say:

> Clone https://github.com/Alfonso-Castano/claude-init-project and install it: copy `skills/init-project` into `~/.claude/skills/` and everything in `agents/` into `~/.claude/agents/`.

Claude Code has git and bash access by default and will do this itself — no scripts to run by hand. You only need to say this once per machine; after that `~/.claude/` already has it and every project picks it up automatically.

**Manual equivalent**, if you'd rather run it yourself — see [Quick install](#quick-install) above for the one-liner (`install.sh`), which does exactly this.

## Updating later

If you revise the skill or agent files, push the changes to the repo (`git add . && git commit -m "..." && git push`), then repeat the same one-sentence install on each machine — it'll overwrite the existing `~/.claude/` copies with the latest version.

## Using it

In any project directory, open Claude Code and run:

```
/init-project
```

It only triggers on explicit invocation — it will never fire on its own from conversational cues (`disable-model-invocation: true` in the frontmatter), matching what you asked for: no auto-trigger, since you only run this once per project and always deliberately.

## What it produces

A `.context/` directory in the project root:

- `OVERVIEW.md` — always
- `research/` — only if you accept the research offer
- `ROADMAP.md` — only if the roadmapper agent decides the project actually needs phases
- `DECISIONS.md` — always (may be a thin seed)
- `STATE.md` — always

No `.claude/` scaffolding, no `config.json`, no CLAUDE.md changes — all of that was deliberately dropped per our discussion.

## Using /update-context

In a project that already has `.context/` (from `/init-project`), run:

```
/update-context
```

Like `/init-project`, it only triggers on explicit invocation
(`disable-model-invocation: true`) — it never fires on its own from
conversational cues. It delegates the actual git-history read and file
writes to the `context-updater` subagent, running in its own isolated
context so the main session's context budget isn't spent on it. If
`.context/` doesn't exist yet in the current project, it says so and stops
— it never creates one (`/init-project` is the only thing that does that).

**What it updates:**

- `STATE.md` — overwritten in place with a fresh snapshot (Current Position, Next Action)
- `DECISIONS.md` — appended to, only if the git evidence shows a genuine new decision
- `ROADMAP.md` — updated only if it already exists and a phase transitioned
- `OVERVIEW.md` and `research/` — left untouched (static by design)

**The staleness hook:** once installed, every new session prints a one-line
stderr note if `STATE.md` is stale relative to new git activity — a visible
nudge to run `/update-context`, not an automatic update. It never writes
files and never invokes Claude on its own.
