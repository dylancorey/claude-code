# The Ledger

A personal log of restaurants and bars, movies and TV, and concerts and live events.
Notes rather than ratings — the note is the part worth rereading.

**Live page:** https://claude.ai/code/artifact/7b605c39-2263-438a-b9bc-d10ed7c6a127

`ledger.html` is the source. The published page is self-saving: it declares the
`artifact` capability, so adding or editing an entry on the page publishes a new
version of itself to that same URL. There is no separate database file.

Navigation: search across every field, category filter (the big number row),
been-there / want-to toggles, sort, and a tag filter bar. Tags stack — selecting
two narrows to entries carrying both — and each chip shows how many entries it
would leave, so combinations that lead nowhere are visible before you click.
Tags are stored lowercase.

## Data shape

Entries live in the `<script id="entry-data" type="application/json">` block:

```json
{
  "id": "e1",
  "category": "food",          // food | screen | live
  "status": "logged",          // logged | wishlist
  "title": "Lucali",
  "date": "2026-05-02",        // YYYY-MM-DD, or "" for something not done yet
  "fields": { "city": "", "cuisine": "", "dish": "" },
  "with": "Ari and Jess",
  "tags": ["pizza", "brooklyn"],
  "note": "Free text — the part that matters."
}
```

Per-category `fields`:

| category | fields | statuses |
| --- | --- | --- |
| `food` | `city`, `cuisine`, `address`, `dish` | `logged` (Been there), `wishlist` (Want to go) |
| `screen` | `kind`, `year`, `by`, `where` | `logged` (Watched), `watching` (Watching), `wishlist` (Want to watch) |
| `live` | `kind`, `venue`, `city`, `address`, `support` | `logged` (Went), `wishlist` (Want to go) |

Status keys are shared across categories but their labels are per-category, and
`watching` is only offered on `screen`. An `address` (or failing that, title +
venue + city) becomes a Google Maps link on the card and in the detail view.

Adding a category means adding one object to `CATS` in the page script — the form,
the filter tabs, and the metadata line all read from it.

## The extras

| Feature | What it does |
| --- | --- |
| **Spin it** | Picks at random off the want-to list. Respects the active category filter, so "Food" + Spin only offers restaurants. |
| **Order again** | Every `dish` you flagged on a food entry, in one list. Tap the place name to open the entry. |
| **Year in review** | Per-year counts, top tags, who you were with most, first and last outing, cities, nights away. Year picker flips between years. |
| **Suggest something** | Ranks your want-to list against your own history — tag overlap, repeated cuisines and kinds, neighborhoods you return to, and how long it has been since you logged that category — and shows why. Below it, observations: a companion you have not seen lately, your most-repeated tag, a dish past-you flagged. Runs entirely in the page. |
| **Voice** | `tone` is `plain`, `dry`, or `salty`. It rewrites the empty states, the spin captions, and the suggestion intro. Salty swears at the situation. Set it in Settings. |
| **Appearance** | Auto / Light / Dark in the header. Auto follows the Claude viewer theme; an explicit choice wins over it and is remembered per browser in `localStorage`, not in the ledger. |
| **On this day** | A strip above the grid when today's month and day match an entry from an earlier year. Absent otherwise. |
| **Away markers** | Any entry whose `city` isn't home gets an Away chip and counts toward the away tally. Screen entries have no city, so they never count. |

`home` sits alongside `hasSamples` and `entries` at the top of the JSON block. It
is a **comma-separated list**, not one city: the first item is the display name,
the rest are neighborhoods that still count as home. Seeded for Los Angeles
(90069) with WeHo, Silver Lake, Santa Monica and the other usual names, and
editable from Year in review.

Matching is whole-word on a punctuation-stripped, lowercased form of both sides,
so `LA` matches "Downtown LA" but not Atlanta, Dallas, Portland, or Oakland.

## Telling Claude to update it

Paste this into a Claude project's instructions:

> My activity ledger lives at https://claude.ai/code/artifact/7b605c39-2263-438a-b9bc-d10ed7c6a127
>
> When I mention a restaurant, bar, movie, show, concert, or live event I went to
> or want to go to, update the ledger: read it with the Artifact tool, add or edit
> the entry in the JSON block with id "entry-data", and publish back to the same
> URL. Categories are food, screen, and live. Status is "logged" or "wishlist".
> Tags are lowercase. Keep my wording in the note. Put street addresses in
> fields.address on food and live entries so map links work.
>
> If I say what to order at a restaurant, put it in the food entry's "dish"
> field — it feeds the Order this again list. "home" at the top level is my
> home base city; anything logged in a different city is marked Away.

Then: "Add Lucali to my ledger — went last night with Ari, get the calzone."

## Claude-written suggestions

The page cannot call Claude at runtime — the account's artifact runtime serves
`artifact`, `downloads`, `mcp` and `self`, with no text-generation capability —
so the in-page suggestions are computed, not generated. To add written ones,
Claude sets the top-level `recs`:

```json
{ "at": "2026-08-29", "items": [ { "category": "food", "title": "...", "body": "..." } ] }
```

They render above the computed picks under a "From Claude" heading. Ask for them
in the project and they are written into the ledger like any other edit.
