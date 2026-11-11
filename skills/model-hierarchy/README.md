# model-hierarchy

Routes multi-step coding work to the cheapest Claude model that can do each step correctly. The main session orchestrates; up to four subagents do the work.

## Install (per project)

From the project root, with this repo cloned at `<skills-repo>`:

```sh
mkdir -p .claude/skills && cp -R <skills-repo>/skills/model-hierarchy .claude/skills/ && sh .claude/skills/model-hierarchy/install.sh --profile eco
```

- `--profile eco|balanced|power` picks the model and effort written into each agent file (default `balanced`).
- `--user` installs to `~/.claude/agents/` for all projects instead of `./.claude/agents/`. It combines with `--profile`.
- Re-running is safe. An agent file that differs is backed up to `.bak` before it is replaced. Switching to `eco` moves an existing `fable-escalation.md` to `.bak`.
- The installer records the profile in `.claude/model-hierarchy-profile` and prints the recommended `/model` and `/effort` commands. Run `/agents` afterwards to verify.
- Cloud sessions (claude.ai/code, mobile, desktop cloud) start from a fresh clone. Commit `.claude/skills/model-hierarchy`, `.claude/agents/` and `.claude/model-hierarchy-profile`; `--user` does not persist there.

## Profiles

| Profile | haiku-worker | sonnet-coder | opus-architect | fable-escalation | Main session |
| --- | --- | --- | --- | --- | --- |
| `eco` | haiku, low | sonnet, medium | opus, high (after two failures; security/architecture first) | not installed | `/model sonnet`, `/effort medium` |
| `balanced` (default) | haiku, low | sonnet, medium | opus, high | claude-fable-5-2, xhigh | `/model opus`, `/effort medium` |
| `power` | haiku, low | sonnet, high | opus, xhigh | claude-fable-5-2, xhigh | `/model opus`, `/effort high` |

**`eco` is the best fit for Pro limits:** no Fable, Sonnet as the orchestrator, and Opus only when needed. `/model` and `/effort <level>` save your choice as the default for later sessions.

## Tiers

| Tier | Responsibilities |
| --- | --- |
| haiku-worker | Read-only exploration, grep/glob, log summaries, running tests/linters, formatting, renames, boilerplate, simple docs |
| sonnet-coder | Default implementer: features, known-cause bug fixes, refactors, unit tests, docs |
| opus-architect | Architecture, unknown-cause debugging, security/concurrency/performance code, plans, reviews |
| fable-escalation | Hardest, long-horizon tasks only (balanced and power) |

The orchestrator also adapts to the main session's model. On Haiku it warns once and hands planning up sooner. On Opus or Fable it delegates more work down.

## Fable fallback

Fable is not guaranteed on every plan. If `fable-escalation` replies `FABLE_UNAVAILABLE`, fails with an API error, or reports it switched models, the orchestrator reruns the step on `opus-architect` and does not retry Fable that session.

> **Usage credits:** on Pro and some other plans, Fable usage can bill to usage credits instead of your plan's included limits. The orchestrator tells you before its first Fable call in a session. Use `eco` to avoid Fable entirely.

## Settings to avoid

- Keep **ultracode OFF** (`/effort ultracode off`) while using this skill: it has Claude orchestrate its own workflows and bypasses tier routing. Typing the word `ultracode` in a prompt also starts a workflow.
- Do not set `CLAUDE_CODE_SUBAGENT_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, or `CLAUDE_CODE_EFFORT_LEVEL`; they override the per-agent model and effort.

Requires Claude Code v2.1.321+ for Fable 5.2.
