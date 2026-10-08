# Orchestration

## Roles
- Lead (sonnet, high effort): plans and executes
- scout subagents (haiku, medium effort): file discovery and docs retrieval only
- Advisor (opus, via /advisor): strategic review on call

## Dispatch
- Run at most 3 scout subagents in parallel
- Scouts return structured AST summaries and docs snippets only. They never modify files or return raw file dumps

## Advisor checkpoints
- Consult /advisor opus before finalizing any plan that touches multiple files or modules
- Summon /advisor opus automatically when the same test or compiler error fails twice
- Before declaring a task complete or staging a git commit, run an advisor diff contract audit:
  compare the diff against the stated requirements and report gaps, unrequested changes, and unverified claims
