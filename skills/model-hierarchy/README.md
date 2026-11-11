# model-hierarchy

Routes multi-step coding work to the cheapest Claude model that can do each step correctly. The main session orchestrates; four subagents do the work.

## Install (per project)

From the project root, with this repo cloned at `<skills-repo>`:

```sh
mkdir -p .claude/skills && cp -R <skills-repo>/skills/model-hierarchy .claude/skills/ && sh .claude/skills/model-hierarchy/install.sh
```

Use `sh install.sh --user` to install the agents for all projects (`~/.claude/agents/`). Then run `/agents` in Claude Code to verify. Re-running is safe: an existing agent file that differs is backed up to `.bak` before it is replaced.

## Tiers

| Tier | Model | Effort | Responsibilities |
| --- | --- | --- | --- |
| haiku-worker | `haiku` | `low` | Read-only exploration, grep/glob, log summaries, running tests/linters, formatting, renames, boilerplate, simple docs |
| sonnet-coder | `sonnet` | `medium` | Default implementer: features, known-cause bug fixes, refactors, unit tests, docs |
| opus-architect | `opus` | `high` | Architecture, unknown-cause debugging, security/concurrency/performance code, plans, reviews |
| fable-escalation | `claude-fable-5-2` | `xhigh` | Hardest, long-horizon tasks only |

Keep the main session at `medium` effort. The orchestrator may retry a step on the same tier at higher effort before escalating to a bigger model.

## Fable fallback

Fable is not guaranteed on every plan. If `fable-escalation` replies `FABLE_UNAVAILABLE`, fails with an API error, or reports it switched models, the orchestrator reruns the step on `opus-architect` and does not retry Fable that session.

> **Usage credits:** on Pro and some other plans, Fable usage can bill to usage credits instead of your plan's included limits. The orchestrator tells you before its first Fable call in a session.

## Settings to avoid

- Keep **ultracode OFF** (`/effort ultracode off`) while using this skill: it has Claude orchestrate its own workflows and bypasses tier routing. Typing the word `ultracode` in a prompt also starts a workflow.
- Do not set `CLAUDE_CODE_SUBAGENT_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, or `CLAUDE_CODE_EFFORT_LEVEL`; they override the per-agent model and effort.

Requires Claude Code v2.1.321+ for Fable 5.2.
