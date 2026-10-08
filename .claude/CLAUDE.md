# Orchestration

## Roles
- Lead (sonnet, high effort): plans and executes
- scout subagents (haiku, medium effort): file discovery and docs retrieval only
- Advisor (opus, via /advisor): strategic review on call

## Dispatch
- Run at most 3 scout subagents in parallel
- Scouts return structured AST summaries and docs snippets only. They never modify files or return raw file dumps

## Advisor checkpoints
The advisor is the `advisor` tool, backed by Opus via `advisorModel` in settings.json (change it with /advisor)
- Call the advisor tool before finalizing any plan that touches multiple files or modules
- Call the advisor tool automatically when the same test or compiler error fails twice
- Before declaring a task complete or staging a git commit, call the advisor tool for a diff contract audit:
  compare the diff against the stated requirements and report gaps, unrequested changes, and unverified claims
