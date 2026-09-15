# The Ledger

A personal log of restaurants and bars, movies and TV, concerts and live events,
and places. Notes rather than ratings — the note is the part worth rereading —
plus one yes/no: would I go again.

**Live page:** https://claude.ai/code/artifact/7b605c39-2263-438a-b9bc-d10ed7c6a127
**Audit and build log:** https://claude.ai/code/artifact/b8e5c334-e5de-402f-a3cd-0eb8666acd48

`ledger.html` is the whole app: styles, data, and script in one file. The
published page saves itself — every add, edit, or delete publishes a new version
of the page to the same URL through the `artifact` capability. There is no
separate database. Version history is the undo stack for anything the in-page
trash does not cover.

## What it runs on

Three runtime capabilities, declared at publish time, contract 0.2.49:

| Capability | Used for | If unavailable |
| --- | --- | --- |
| `artifact` | Saving. Each change republishes the page. | Page goes read-only and says so. |
| `downloads` | Settings → Save backup file (`.json`) and Save as spreadsheet (`.csv`). | Same button copies to the clipboard and says so. |
| `sample` | Log it, Recap, Sharpen — see below. Runs only on a tap, on the viewer's own Claude account, asks once. | The buttons hide. Everything else works. |

Not declared, on purpose: `mcp` and `assets` both end the public share link.
Real restaurant and event data comes in through Claude in a session instead —
verified, attributed, then published into the catalog.

The page cannot reach the internet itself: published artifacts run under a CSP
that blocks every outbound request.

## Data shape

Everything lives in the `<script id="entry-data" type="application/json">` block:
`tone`, `home`, `recs`, `catalog`, `catalogAt`, `entries`, `trash`.

An entry:

```json
{
  "id": "emtqclwwzqcly",
  "category": "food",                 // food | screen | live | place
  "status": "logged",                 // logged | watching (screen only) | wishlist
  "title": "Formosa Cafe",
  "date": "2026-09-05",               // event date, YYYY-MM-DD, or "" if not done yet
  "fields": { "city": "WeHo", "cuisine": "Chinese", "address": "", "dish": "Beef" },
  "with": "Melissa, Trish",
  "tags": [],
  "note": "",
  "again": true,                      // true | false | null — null is "not answered", never false
  "createdAt": "2026-09-06T21:54:07.314Z",
  "updatedAt": "2026-09-06T21:54:07.314Z",
  "source": "Wikipedia",              // only on entries saved from Discovery
  "sourceUrl": "https://..."
}
```

Per-category `fields`:

| category | fields | statuses |
| --- | --- | --- |
| `food` | `city`, `cuisine`, `address`, `dish` | Been there · Want to go |
| `screen` | `kind`, `year`, `by`, `where` | Watched · Watching · Want to watch |
| `live` | `kind`, `venue`, `city`, `address`, `support` | Went · Want to go |
| `place` | `kind`, `city`, `address` | Been there · Want to go |

`createdAt` is set on save and back-filled from the id's embedded timestamp
where that parses; the two seeded entries keep `null`. Switching category in the
form prunes fields the new category does not declare, after asking if any hold
text. `city` and `address` survive any switch.

Deleted entries move to `trash` with a `deletedAt`; a ten-second Undo appears,
and Settings → Trash restores or purges. Nothing purges on a timer.

Adding a category is one object in `CATS` — the form, the stat row, the summary
line, and the CSV export all read from it.

## Getting things in

**Log it** — one line at the top of the Ledger tab: *"Sonny's pizza with Trish,
get the margherita."* With Claude available, the line is parsed on the quick tier
into category, title, who, dish, date, tags, and note, then opened in the normal
form flagged "Claude filled this in — check it." Without Claude, the same line
opens the form with the title filled. Nothing saves without the review step, and
the parser is told never to invent an address, year, director, or cuisine.

**Add entry** — the full form. **Log again** — on any done entry's detail view,
opens a new entry prefilled with that place's city, cuisine, address and so on;
only the date (today), who with, and the note are left blank for you to fill in.
No duplicate warning — saying "log again" is already telling the ledger it's a
repeat. **Discover** — search the catalog, save a result prefilled. **Or tell
Claude** in a project (the exact instructions are in the page under How this
works).

## Finding things

Search across every field. Category from the stat row. Been-there / Watching
toggles, sort (Recent / Oldest / A–Z), stacking tag chips with live counts, and a
per-person filter — tap a name in any entry. Filters persist in `localStorage`
and mirror into the URL hash, so a filtered view can be bookmarked. Filtering by
a person shows a summary line above the results — outings together, days since
the last one, anything shared on the want-to list — with a link to switch tabs
and see it.

**Want to** is its own tab: everything with status `wishlist`, sorted by when it
was added. The main list is only things that happened.

Keyboard: `/` search, `n` new entry, `?` this list, `Cmd/Ctrl+Enter` saves the
open form, `Esc` closes.

## On a phone

Below 46rem a fixed bottom bar replaces the header tools: **Ledger · Want to ·
Discover · You**. *You* is a bottom sheet with Suggest, Spin, Order again, Year in
review, Settings, and the theme switch. The sticky top bar keeps search, a
Filters button that opens a sheet, and a "+" for a new entry. Between 48 and
64rem the grid is three columns.

## The extras

| Feature | What it does |
| --- | --- |
| **Suggest something** | Ranks the want-to list against your history — tag overlap, repeated cuisines, neighborhoods you return to, category gaps, and now whether comparable things were marked "again" — and says why. **Sharpen with Claude** rewrites the three reasons from the actual entries in one quick call. |
| **Spin it** | Random pick off the want-to list, respecting the category filter. |
| **Order again** | Every `dish` you flagged, in one list. |
| **Year in review** | Per-year counts, top tags, companions, first/last, cities, home/away/unknown. Entries with no date fall back to the year they were added and are marked approximate. Two extra scopes sit alongside the calendar years: **All time** (lifetime totals, a most-repeated title, a longest-weeks-in-a-row streak, and which home neighborhoods have never been logged) and **Last 90 days** (the same shape, rolling). **Recap** writes four to six sentences about the month or a specific year in the ledger's voice, from the entries only, with Stop and Write-it-again — it only appears on a real year, not the two lifetime scopes. |
| **Said I'd go back** | Every entry marked "would go again" that was never revisited, oldest first. An entry counts as revisited if a later entry with the same title and category exists. |
| **This week** | A strip above the grid counting entries this week. On this day takes precedence when a prior year matches. |
| **Voice** | `tone` is `plain`, `dry`, or `salty`. It rewrites the empty states, spin captions, and the recap's register. Discovery blurbs keep whatever voice they were indexed in. |
| **Appearance** | Auto / Light / Dark, plus Comfortable / Compact density. Both remembered per browser, not in the ledger. |
| **Away** | `home` is a comma-separated list — display name first, then neighborhoods that still count as home — edited as chips in Settings. Anything logged elsewhere is Away; no city at all is Unknown, and the review tile says so rather than guessing. |
| **Offline** | Every change is mirrored to `localStorage` before publishing. Offline, the save waits and retries on reconnect. On load, unsaved changes newer than the page are offered back, never restored silently. |

## Discovery

A catalog of real, sourced items across movies and TV, restaurants, live events,
and things to do. Each result shows the useful facts, a candid blurb, a link back
to the source, and a map link; **Save to ledger** opens the normal form prefilled.
Titles already in the ledger show "In your ledger" instead.

Search matches any word (stopwords dropped), ranks multi-word matches and exact
titles higher, and boosts restaurants and places near the Near box — which
understands *westside*, *valley*, *eastside*, and *beach* as well as neighborhood
names. Live events get their own scope.

Item shape:

```json
{ "id": "unique", "kind": "screen | food | place | live", "title": "...",
  "year": "2022", "by": "director or creator", "form": "Film | Museum | Comedy | ...",
  "cuisine": "...", "city": "...", "address": "street address or empty",
  "venue": "live only", "when": "Oct 3, Sat · 8:30 PM", "date": "2026-10-03",
  "tags": ["lowercase"], "w": 1, "q": "extra search words",
  "blurb": "what it is, why bother, the drawback",
  "source": "StubHub", "sourceUrl": "https://...",
  "verifiedAt": "2026-09-15" }
```

`w` is 1–5 prominence. `verifiedAt` is the date the details were checked against
a live source, or `null` if they were not — never a guess. Use only facts present
in the source and leave a field out rather than invent one; the card says when an
address is missing and maps by name instead.

Stocking it is a request in a session: *"stock Discovery with Thai places near
WeHo and comedy shows this month."* Sources so far: Wikipedia, StubHub, Time Out,
LA Weekly, Fodor's, Yelp, Tripadvisor, Beverly Press, Visit California, Discover
Los Angeles.

## Privacy, plainly

The ledger lives in the owner's Claude account. Anyone with the share link sees
every entry, note, and name; there is no per-entry privacy on a shared page. The
Claude features send only the entries they need, only when tapped, and Claude
keeps nothing between taps. No API key or credential is in the page.
