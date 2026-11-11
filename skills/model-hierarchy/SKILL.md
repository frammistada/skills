---
name: model-hierarchy
description: Orchestrates multi-step coding work across a tiered team of subagents (haiku-worker, sonnet-coder, opus-architect, fable-escalation) so each step runs on the cheapest model that can do it correctly. Use for any multi-step coding task - features spanning several files, refactors, debugging sessions, migrations, test suites, or mixed research-plus-implementation work. Skip for one-shot questions and edits of one or two files.
---

# Model hierarchy

The main session is the orchestrator: it plans, splits the task, classifies each step, delegates with a precise spec, and reviews the results. Requires the four agents from `agents/` installed (run `install.sh`, then `/agents` to verify).

## Planning and routing

1. Plan the task, split it into steps, and classify each step by difficulty.
2. Route each step to the cheapest tier that can do it correctly:
   - Mechanical or read-only (including boilerplate, formatting, renames, simple docs) -> `haiku-worker`
   - Well-defined coding -> `sonnet-coder`
   - Ambiguous, risky, architectural, or failed twice -> `opus-architect`
   - Hardest or longest-horizon -> `fable-escalation` if available, otherwise `opus-architect`
3. Non-code work: research and summaries -> `haiku-worker`; docs and READMEs -> `sonnet-coder`; plans, trade-off analysis, reviews -> `opus-architect`.
4. Tie-breaking: when a step sits between two tiers, pick the higher one if it touches security, data loss, public APIs, or concurrency; otherwise pick the lower one. Never downgrade security-sensitive or architectural work to save cost.

## When NOT to delegate

Do the work directly in the main session if it touches one or two files, needs under ~20 lines of change, or the handoff spec would be as long as the work. Delegation must pay for its own overhead.

## Delegation mechanics

- Only the main session delegates. The agents are built without the Agent tool, so they cannot spawn subagents.
- Handoff contract - every delegation includes:
  1. Goal
  2. Exact file paths
  3. Constraints and conventions to follow
  4. Acceptance criteria
  5. What to return
  Workers see no conversation history. Never assume context.
- Parallelism: run in parallel only read-only tasks or writes to disjoint files. Never let two writers touch the same file; serialize those.
- Workers return concise summaries (changes, files touched, open risks), not dumps.

## Verification and failure handling

- After any `sonnet-coder` change, `haiku-worker` runs tests/lint and reports. `opus-architect` reviews the diff only for non-trivial changes.
- On failure, the worker returns the error and what it tried. Escalate one tier with that report included (after two failures, or when the worker reports uncertainty); see the Effort policy for retrying at higher effort first. Never retry blind.
- Never set or rely on `CLAUDE_CODE_SUBAGENT_MODEL` or `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (they can override the per-agent models), or `CLAUDE_CODE_EFFORT_LEVEL` (it overrides every agent's `effort`).

## Effort policy

Each agent sets its own `effort`: haiku-worker `low`, sonnet-coder `medium`, opus-architect `high`, fable-escalation `xhigh`.
- Before escalating a step to a bigger model, you may first retry on the same tier at higher effort by passing `effort` on the Agent call (e.g. sonnet-coder at `high`). That is often cheaper than a model jump. Judge cost per accepted result, not per run.
- Keep the main session at `medium` effort. Do not change model or effort mid-session without need: a model switch always rebuilds the prompt cache, and an effort change does too on older models.
- Ultracode must stay OFF while this skill is active: it lets Claude orchestrate its own workflows and bypasses tier routing. It is a session toggle (`/effort ultracode off`); never write it into a settings file or an agent file. If the user turned it on, ask them to turn it off.

## Fable fallback

Fable access is not guaranteed (e.g. on Pro it may be missing or billed to usage credits). Before the first `fable-escalation` call in a session, tell the user it may use Fable usage credits. Route the step to `opus-architect` instead, passing the same spec, if any of these happen:
- The agent replies `FABLE_UNAVAILABLE: ...`
- The Agent call fails with an API error (model unavailable, billing, `Agent terminated early due to an API error`)
- The report opens with `This agent switched to <model>`, meaning it did not run on Fable
Do not retry Fable in the same session after a fallback.

## Classification cheat sheet

| Example task | Tier |
| --- | --- |
| Find every caller of `parseConfig` and list the files | haiku-worker |
| Run the test suite and summarize failures | haiku-worker |
| Rename a module across the repo with `git mv` + formatter | haiku-worker |
| Add a CLI flag with spec'd behavior and a unit test | sonnet-coder |
| Fix a bug whose cause is already identified | sonnet-coder |
| Write a README for an existing module | sonnet-coder |
| Intermittent test failure, cause unknown | opus-architect |
| Add auth checks / input validation to API endpoints | opus-architect |
| Design the schema and module split for a new feature | opus-architect |
| Migrate a large codebase to a new framework over many steps | fable-escalation (fallback: opus-architect) |
