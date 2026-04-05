---
name: complete-phase
description: Execute one plan phase — implement, simplify, test, review, commit, push, mark complete.
argument-hint: [plan-file] [phase-number]
disable-model-invocation: true
---

# /complete-phase — Execute a Plan Phase End-to-End

Automates the full cycle for one phase of a plan: implement → simplify → test → review → feed forward → commit → push → update plan.

## Arguments

- `$1` — plan file path (**required**). If the argument contains no `/`, resolve relative to `~/.claude/plans/`.
- `$2` — phase/step number (**optional**). If omitted, auto-detect the first incomplete phase (see Phase Detection below).

## Phase Detection (when `$2` is omitted)

Scan the plan file for the first incomplete phase using these heuristics, in order:

1. First unchecked checkbox item under a phase heading: `- [ ]`
2. First phase heading that does NOT contain a `COMPLETE` or `DONE` marker
3. If ambiguous or no clear match, use AskUserQuestion to ask the user which phase to run

## Workflow Stages

Execute these stages **in strict order**. If any stage fails, **stop immediately** and report the failure — never skip a stage.

---

### Stage 1 — Preflight

1. Run `git status --short` to check working tree state. If there are uncommitted changes, check whether they appear to be work from the target phase (e.g., the user already implemented and is running the skill to finish the cycle). If so, note it and skip Stage 2 (Implement). If the changes look unrelated, warn the user and ask whether to proceed or stash first.
2. Resolve the plan file path per the argument rules above. Read the file and confirm it exists.
3. Identify the target phase (from `$2` or auto-detection). Print the phase title and a brief summary of what will be implemented.
4. Ask the user to confirm before proceeding.

### Stage 2 — Implement

1. Read the target phase's description, requirements, and acceptance criteria from the plan.
2. Implement all code changes described in the phase.
3. After implementation, run the project's build/check command (e.g., `pnpm build`, `pnpm typecheck`) to verify there are no build errors. Fix any that arise.

### Stage 3 — Simplify

Invoke `/simplify` to refactor the implementation for reuse, quality, and efficiency.

This restructures the code while it's fresh — before tests lock in the API surface.

### Stage 4 — Test

1. Write thorough tests for the implemented code:
   - Happy-path tests for each function/feature
   - 2–3 edge cases per function (empty inputs, boundary values, error conditions)
2. Run the test suite: `pnpm test`
3. If tests fail, fix the failures and re-run until all pass.

### Stage 5 — Review

Invoke `/review` as the **final quality gate**. This runs on code that is both clean (post-simplify) and proven working (post-test).

**No code changes after this stage.** The review is the last analytical pass. If review surfaces critical issues, fix them, re-run tests, and re-review before proceeding.

### Stage 6 — Feed Forward

Review what happened during implementation, simplify, test, and review for lessons that affect **upcoming phases** in the plan. This stage should be used sparingly — only when something genuinely changes the picture for later work.

Look for:
- **Discoveries** — an API behaves differently than assumed, a dependency has limitations, a data model needed unexpected changes
- **Risks surfaced** — a pattern that worked here but will be fragile at scale, a missing prerequisite for a later phase
- **Plan adjustments** — a later phase's scope needs to shrink/grow, steps need reordering, a new step is needed

**When there is something to feed forward:**

1. Edit the plan file to add a `> **Note from phase N:**` blockquote under each affected future phase, briefly describing the lesson and its implication.
2. If the discovery is significant enough to change a phase's scope or approach, also update that phase's description — but keep the original text visible (use strikethrough or a "Previously: ..." note so the change is traceable).
3. **Always report feed-forward changes to the user** before proceeding. Print a clear summary:
   ```
   === Feed Forward ===
   Phase 5: Added note — auth token refresh needs retry logic (discovered during Phase 3 API integration)
   Phase 7: Updated scope — removed Redis caching step (not needed after Phase 3 simplified the data model)
   ```
4. Ask the user to confirm the plan changes are acceptable before continuing.

**When there is nothing to feed forward:** Simply state "No feed-forward notes — plan unchanged" and move on. Do not force notes where none are needed.

### Stage 7 — Commit

1. Stage all implementation changes (code + tests, but NOT the plan file).
2. Craft a commit message that:
   - References the phase number and title (e.g., `phase 3: add user authentication`)
   - Summarizes what was implemented in 1–2 sentences
3. Create the commit.

### Stage 8 — Push

1. Push to the remote branch.
2. If the branch has no upstream, set one with `git push -u origin <branch>`.
3. If the push fails due to remote changes, run `git pull --rebase` and retry the push.

### Stage 9 — Update Plan

The plan file is a tracked markdown file that lives in the repo. Its completion state must be committed and pushed separately from the implementation.

1. Edit the plan file to mark the phase as complete:
   - Check off any `- [ ]` items → `- [x]`
   - Add a completion marker to the phase heading or body, e.g.: `COMPLETE — 2026-04-05 — abc1234`
   - Include the timestamp (YYYY-MM-DD) and the short commit hash from Stage 7
2. If Stage 6 (Feed Forward) made changes to the plan file, those edits are included in this commit alongside the completion marker.
3. Stage **only** the plan file.
4. Commit with message: `docs: mark phase N complete`
5. Push this commit to the remote.

This keeps the implementation commit clean and the plan's history separately trackable.

---

## Summary Output

After all stages complete, print a summary:

```
=== Phase Complete ===

Phase:       <number> — <title>
Commit:      <short hash> — <commit message>
Plan:        <plan file path> updated and pushed
Feed forward: <N notes added to future phases> (or "none")

Next phase:   <number> — <title> (or "All phases complete!")
```

If there is a next phase, output a ready-to-paste prompt so the user can kick it off immediately:

```
Ready to continue? Paste this:

/complete-phase <plan-file> <next-phase-number>
```

This saves the user from having to look up the file path and phase number.

## Safety Rules

- **Never skip stages** — the order is intentional (simplify → test → review ensures review sees clean, working code)
- **Stop on failure** — report what failed and which stage, so the user can fix and re-run
- **Check working tree** — if uncommitted changes exist, determine if they're phase work (skip implement) or unrelated (warn user)
- **Two separate commits** — implementation and plan update are always separate commits
- **Feed forward sparingly** — only add notes when something genuinely affects future phases; always report changes to the user and get confirmation
- **Confirm before starting** — always show the user what phase will run and wait for confirmation
