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

| category | fields |
| --- | --- |
| `food` | `city`, `cuisine`, `dish` |
| `screen` | `kind`, `year`, `by`, `where` |
| `live` | `kind`, `venue`, `city`, `support` |

Adding a category means adding one object to `CATS` in the page script — the form,
the filter tabs, and the metadata line all read from it.

## The extras

| Feature | What it does |
| --- | --- |
| **Spin it** | Picks at random off the want-to list. Respects the active category filter, so "Food" + Spin only offers restaurants. |
| **Order again** | Every `dish` you flagged on a food entry, in one list. Tap the place name to open the entry. |
| **Year in review** | Per-year counts, top tags, who you were with most, first and last outing, cities, nights away. Year picker flips between years. |
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
> Tags are lowercase. Keep my wording in the note.
>
> If I say what to order at a restaurant, put it in the food entry's "dish"
> field — it feeds the Order this again list. "home" at the top level is my
> home base city; anything logged in a different city is marked Away.

Then: "Add Lucali to my ledger — went last night with Ari, get the calzone."
