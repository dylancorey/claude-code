#!/usr/bin/env bash
# Claude Code status line: context bar, percent used, mood label, running cost.
# Reads the status JSON from stdin. Example output:
#   Chat space ▓▓▓▓▓░░░░░ 50% used. Getting fuller.   Cost so far: $1.20
#
# Never fails loudly: if jq is missing or the JSON is unexpected, it prints a
# reduced line instead of an error, so the status bar is never blank or noisy.

export LC_ALL=C   # keep printf decimal handling predictable across locales

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "Chat space ?% used. (install jq for details)"
  exit 0
fi

num() { [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; }

cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input" 2>/dev/null)
num "$cost" || cost=0
cost=$(printf '%.2f' "$cost")

pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input" 2>/dev/null)
if ! num "$pct"; then
  # Fallback: derive from the latest usage and window size
  pct=$(jq -r '
    (.context_window.context_window_size // 0) as $max
    | (.context_window.current_usage // {}) as $u
    | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
    | if $max > 0 and $used > 0 then ($used * 100 / $max) else empty end' <<<"$input" 2>/dev/null)
fi
if ! num "$pct"; then
  # No usable context number: show an unknown reading rather than a false 0%
  printf 'Chat space ?%% used.   Cost so far: $%s\n' "$cost"
  exit 0
fi

pct=$(printf '%.0f' "$pct")
(( pct > 100 )) && pct=100
(( pct < 0 )) && pct=0

width=10
filled=$(( (pct * width + 50) / 100 ))
bar=""
for ((i = 0; i < width; i++)); do
  if (( i < filled )); then bar+="▓"; else bar+="░"; fi
done

if   (( pct < 40 )); then label="Plenty of room."
elif (( pct < 70 )); then label="Getting fuller."
elif (( pct < 90 )); then label="Getting tight."
else                      label="Nearly full, consider /compact."
fi

printf 'Chat space %s %s%% used. %s   Cost so far: $%s\n' "$bar" "$pct" "$label" "$cost"
