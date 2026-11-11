# model-hierarchy

Routes multi-step coding work to the cheapest Claude model that can do each step correctly. The main session orchestrates; four subagents do the work.

## Install (per project)

From the project root, with this repo cloned at `<skills-repo>`:

```sh
mkdir -p .claude/skills && cp -R <skills-repo>/skills/model-hierarchy .claude/skills/ && sh .claude/skills/model-hierarchy/install.sh
```

Use `sh install.sh --user` to install the agents for all projects (`~/.claude/agents/`). Then run `/agents` in Claude Code to verify. Re-running is safe: an existing agent file that differs is backed up to `.bak` before it is replaced.

## Tiers

| Tier | Model | Responsibilities |
| --- | --- | --- |
| haiku-worker | `haiku` | Read-only exploration, grep/glob, log summaries, running tests/linters, formatting, renames, boilerplate |
| sonnet-coder | `sonnet` | Default implementer: features, known-cause bug fixes, refactors, unit tests, docs |
| opus-architect | `opus` | Architecture, unknown-cause debugging, security/concurrency/performance code, plans, reviews |
| fable-escalation | `claude-fable-5-2` | Hardest, long-horizon tasks only |

## Fable fallback

Fable is not guaranteed on every plan (on Pro it may be missing or billed to usage credits). If `fable-escalation` replies `FABLE_UNAVAILABLE`, fails with an API error, or reports it switched models, the orchestrator reruns the step on `opus-architect` and does not retry Fable that session.

Requires Claude Code v2.1.321+ for Fable 5.2. Do not set `CLAUDE_CODE_SUBAGENT_MODEL` or `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`; they can override the per-agent models.
