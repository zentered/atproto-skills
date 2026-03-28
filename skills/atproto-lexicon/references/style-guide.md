# Lexicon Style Guide

Naming conventions, field design guidelines, API patterns, and evolution rules for authoring AT Protocol lexicons.

## Naming Conventions

### Casing Rules

| Context | Style | Example |
|---|---|---|
| Schema names & field names | `lowerCamelCase` | `getProfile`, `displayName` |
| API error names | `UpperCamelCase` | `AccountNotFound` |
| Fixed strings / known values | `kebab-case` | `content-warning` |

### Field Name Constraints

- ASCII alphanumerics only
- No leading digits, no hyphens
- Fields starting with `$` are reserved for the protocol (`$type`, `$link`, `$bytes`)

### Schema Naming Patterns

| Schema Type | Pattern | Examples |
|---|---|---|
| Records | Singular nouns | `post`, `like`, `profile`, `follow` |
| Query endpoints | verb + noun | `getPost`, `listLikes`, `searchActors` |
| Procedure endpoints | verb + noun | `createRecord`, `updateProfile`, `deleteRecord` |
| Subscriptions | `subscribe` + plural noun | `subscribeLabels`, `subscribeRepos` |
| Reusable definitions | `defs` suffix | `app.bsky.feed.defs` |
| Experimental/unstable | `.temp.` or `.unspecced.` in NSID | `app.bsky.unspecced.searchPosts` |

Avoid generic names that conflict with programming language keywords: `default`, `length`, `type`.

## NSID Namespace Organization

- Group related schemas hierarchically: `app.bsky.feed.*`, `app.bsky.graph.*`
- Use `*.defs` files for definitions shared across multiple schemas or consumed by third parties
- Prevent naming conflicts between namespace segments, definitions, and record names

## Field & Type Guidelines

### String Fields

- Always specify `format` when a semantic format exists (DID, handle, datetime, AT URI, etc.)
- Apply `maxLength` constraints for record string fields that lack a format type
- Use `maxGraphemes` for user-facing text with visual/semantic length limits
- Recommended budget: 10–20 bytes per grapheme for `maxLength` when paired with `maxGraphemes`
- Do not redundantly specify both `format` and length limits — formats have their own constraints

### Enum vs knownValues

- Avoid closed `enum` sets — adding new values is a breaking change
- Prefer `knownValues` for extensible value sets
- `knownValues` can reference token definitions for cross-schema extensibility:

```json
{
  "type": "string",
  "knownValues": [
    "com.example.defs#public",
    "com.example.defs#private"
  ]
}
```

### Required Fields

- Mark fields `required` only when truly necessary
- Required fields cannot be made optional later (breaking change)
- Optional boolean fields should default to `false`
- New fields must always be optional

### Data Type Selection

- Use `blob` references for larger text or binary data instead of `string`/`bytes` fields
- Prefer `string` with `format: "cid"` for CID values in most contexts; use `cid-link` only for protocol-level mechanisms
- Use `at-identifier` format in query parameters to accept both DIDs and handles (avoids forcing clients to resolve handles first)
- Record schemas must reference accounts via DIDs, not handles (handles are mutable)

## API Endpoint Design

### Output Specification

Always specify `output` with `encoding` on query and procedure endpoints:

```json
"output": {
  "encoding": "application/json",
  "schema": { "type": "ref", "ref": "#outputSchema" }
}
```

Default encoding: `application/json`.

### Pagination Pattern

Standard cursor-based pagination for list endpoints:

**Query parameters:**
```json
{
  "type": "params",
  "properties": {
    "limit": { "type": "integer", "minimum": 1, "maximum": 100, "default": 50 },
    "cursor": { "type": "string" }
  }
}
```

**Response shape:**
```json
{
  "type": "object",
  "required": ["items"],
  "properties": {
    "items": { "type": "array", "items": { "type": "ref", "ref": "#itemView" } },
    "cursor": { "type": "string" }
  }
}
```

Rules:
- Absence of `cursor` in response means pagination is complete
- Responses may contain fewer items than `limit`
- Cursor values are opaque strings — do not parse or construct them

### Subscription Sequencing

- Optional `cursor` parameter (integer) for replay from a specific point
- All messages include a monotonic `seq` field (may have gaps)
- Missing `cursor` returns new messages going forward
- Server sends `OutdatedCursor` message when requested position is no longer available, triggering backfill from oldest available

### Authentication & Personalization

- Document authentication requirements in endpoint descriptions
- Specify whether responses are personalized (e.g. viewer-specific metadata)
- Clarify field semantics for ambiguous names (e.g. "CID of which record?")

## Evolution & Compatibility Rules

### Immutability of Published Lexicons

Once a lexicon is publicly adopted by third parties, its schema is effectively frozen:

- **Cannot** add required fields
- **Cannot** remove non-optional fields
- **Cannot** change field types
- **Cannot** rename fields
- **Can** add new optional fields
- **Can** add new values to `knownValues` (but not `enum`)

Loosening constraints breaks old software validation; tightening breaks new software. Only optional constraints may be added to previously unconstrained fields.

### Breaking Changes

Breaking changes require a new lexicon under a new NSID. Convention: append version suffix.

```
app.bsky.feed.post      → original
app.bsky.feed.postV2    → breaking revision
```

### Design for Future Growth

- Use object wrappers (single-field objects) instead of bare arrays — allows adding fields to each item later:

```json
// Prefer this:
{ "items": [{ "uri": "at://..." }] }

// Over this:
{ "uris": ["at://..."] }
```

- Use open unions (`"closed": false`) in most scenarios to allow third-party extension
- Consider what fields might be needed later and leave room (but do not add speculative fields)

## Advanced Patterns

### Hydrated Views

Include the original record verbatim plus enriched context. Group viewer-specific metadata under sub-objects for reusability:

```json
{
  "type": "object",
  "properties": {
    "uri": { "type": "string", "format": "at-uri" },
    "record": { "type": "unknown" },
    "author": { "type": "ref", "ref": "#profileView" },
    "viewer": { "type": "ref", "ref": "#viewerState" }
  }
}
```

### RichText Facets

Use `app.bsky.richtext.facet` for text annotations (mentions, links, tags). The feature type union is open, allowing extension with new annotation types.

### Sidecar Records

Define supplementary records using identical record keys in different collections. The sidecar can be updated without invalidating references to the primary record.

### App Modality Signaling

Create known record types with fixed keys to signal active participation. Record presence means active; deletion signals deactivation.

Example: `app.bsky.actor.profile` with `rkey: "self"` — exists when the account is active in the Bluesky app.
