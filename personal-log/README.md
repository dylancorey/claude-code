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

## Telling Claude to update it

Paste this into a Claude project's instructions:

> My activity ledger lives at https://claude.ai/code/artifact/7b605c39-2263-438a-b9bc-d10ed7c6a127
>
> When I mention a restaurant, bar, movie, show, concert, or live event I went to
> or want to go to, update the ledger: read it with the Artifact tool, add or edit
> the entry in the JSON block with id "entry-data", and publish back to the same
> URL. Categories are food, screen, and live. Status is "logged" or "wishlist".
> Keep my wording in the note.

Then: "Add Lucali to my ledger — went last night with Ari, get the calzone."
