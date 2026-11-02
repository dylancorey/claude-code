# Orchestration

## Roles
- Lead (sonnet, high effort): plans and executes. Works alone by default
- scout subagents (haiku, medium effort): broad file discovery and docs retrieval, only when dispatched
- Advisor (opus, via /advisor): strategic review at real decision checkpoints only

## Dispatch
- Default: do the work yourself with Grep, Glob, and Read. Most lookups need one or two searches and no subagent
- Dispatch a scout only for a broad search: the answer spans several directories or modules, the naming is unknown, or a direct search came back empty or too noisy to use
- Never dispatch a scout to read a file you already know the path of, or to find a single symbol
- Run at most 2 scout subagents in parallel, and only when their searches are genuinely independent
- Scouts return structured AST summaries and docs snippets only. They never modify files or return raw file dumps

## Advisor checkpoints
The advisor is the `advisor` tool, backed by Opus via `advisorModel` in settings.json (change it with /advisor)
Call it only at these checkpoints. Do not call it for routine edits, single-file changes, or questions you can settle by reading the code
- Before committing to a plan that changes architecture, public interfaces, data formats, or something hard to undo
- When the same test or compiler error survives two different fix attempts. Call it once per stuck error, not on every retry
- Once per task, before declaring a multi-file task complete, for a diff contract audit:
  compare the diff against the stated requirements and report gaps, unrequested changes, and unverified claims.
  Skip it for single-file or mechanical changes (renames, formatting, dependency bumps)
