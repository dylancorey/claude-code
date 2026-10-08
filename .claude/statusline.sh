#!/usr/bin/env bash
# Claude Code status line: context bar, percent used, mood label, running cost.
# Reads the status JSON from stdin. Example output:
#   Chat space ▓▓▓▓▓░░░░░ 50% used. Getting fuller.   Cost so far: $1.20

input=$(cat)

pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input" 2>/dev/null)
if [ -z "$pct" ]; then
  # Fallback: derive from the latest usage and window size
  pct=$(jq -r '
    (.context_window.context_window_size // 0) as $max
    | (.context_window.current_usage // {}) as $u
    | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
    | if $max > 0 and $used > 0 then ($used * 100 / $max) else empty end' <<<"$input" 2>/dev/null)
fi
if [ -z "$pct" ] || [ "$pct" = "null" ]; then
  # No usable context number: show an unknown reading rather than a false 0%
  cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input" 2>/dev/null)
  printf 'Chat space ?%% used.   Cost so far: $%s\n' "$(printf '%.2f' "${cost:-0}")"
  exit 0
fi
pct=$(printf '%.0f' "$pct")
[ "$pct" -gt 100 ] && pct=100
[ "$pct" -lt 0 ] && pct=0

cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input" 2>/dev/null)
cost=$(printf '%.2f' "${cost:-0}")

width=10
filled=$(( (pct * width + 50) / 100 ))
bar=""
for ((i = 0; i < width; i++)); do
  if [ "$i" -lt "$filled" ]; then bar+="▓"; else bar+="░"; fi
done

if   [ "$pct" -lt 40 ]; then label="Plenty of room."
elif [ "$pct" -lt 70 ]; then label="Getting fuller."
elif [ "$pct" -lt 90 ]; then label="Getting tight."
else                         label="Nearly full, consider /compact."
fi

printf 'Chat space %s %s%% used. %s   Cost so far: $%s\n' "$bar" "$pct" "$label" "$cost"
