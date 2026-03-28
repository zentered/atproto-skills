# Lexicon Type System Reference

Complete reference for all Lexicon field types, container types, meta types, and string format constraints.

## Primary Types

Five primary types are allowed as the `main` definition in a Lexicon file:

### record

Describes objects stored in repositories.

```json
{
  "type": "record",
  "description": "A social follow",
  "key": "tid",
  "record": {
    "type": "object",
    "required": ["subject", "createdAt"],
    "properties": {
      "subject": { "type": "string", "format": "did" },
      "createdAt": { "type": "string", "format": "datetime" }
    }
  }
}
```

- `key` (required): record key type (`tid`, `nsid`, `any`, or literal value)
- `record` (required): an `object` schema defining the record shape

### query

XRPC Query endpoints (HTTP GET).

```json
{
  "type": "query",
  "description": "Get a user's profile",
  "parameters": {
    "type": "params",
    "required": ["actor"],
    "properties": {
      "actor": { "type": "string", "format": "at-identifier" }
    }
  },
  "output": {
    "encoding": "application/json",
    "schema": { "type": "ref", "ref": "#profileView" }
  },
  "errors": [
    { "name": "AccountNotFound" }
  ]
}
```

- `parameters` (optional): `params` type for query string
- `output` (optional): `encoding` (required) + optional `schema`
- `errors` (optional): array of named error conditions

### procedure

XRPC Procedure endpoints (HTTP POST). Same shape as `query` plus an `input` field:

```json
{
  "type": "procedure",
  "description": "Create a new record",
  "input": {
    "encoding": "application/json",
    "schema": { "type": "ref", "ref": "#createInput" }
  },
  "output": {
    "encoding": "application/json",
    "schema": { "type": "ref", "ref": "#createOutput" }
  }
}
```

### subscription

Event Stream endpoints (WebSocket).

```json
{
  "type": "subscription",
  "description": "Subscribe to repo updates",
  "parameters": {
    "type": "params",
    "properties": {
      "cursor": { "type": "integer" }
    }
  },
  "message": {
    "schema": {
      "type": "union",
      "refs": ["#commit", "#handle", "#tombstone"]
    }
  }
}
```

- `message.schema` must be a union of refs
- Optional `cursor` parameter (integer) for replay
- Messages include monotonic `seq` field (may have gaps)

### permission-set

Auth permission bundles.

- `permissions` (required): array of permission definitions
- Optional `title`, `detail` with language variants (`title:lang`, `detail:lang`)

## Concrete Field Types

### boolean

```json
{ "type": "boolean", "default": false, "const": true }
```

- Optional: `default`, `const`
- Query parameter rendering: `true`/`false` (unquoted strings)

### integer

```json
{ "type": "integer", "minimum": 1, "maximum": 100 }
```

- Signed 64-bit; 53-bit recommended for JavaScript compatibility
- Optional: `minimum`, `maximum`, `enum`, `default`, `const`
- No floating-point numbers in ATProto (architecture-dependent rounding)

### string

```json
{
  "type": "string",
  "format": "datetime",
  "maxLength": 256,
  "maxGraphemes": 64
}
```

- Optional: `format`, `maxLength`, `minLength`, `maxGraphemes`, `minGraphemes`, `knownValues`, `enum`, `default`, `const`
- `const` and `default` are mutually exclusive
- `maxLength` counts bytes; `maxGraphemes` counts user-perceived characters

### bytes

```json
{ "type": "bytes", "maxSize": 1000000 }
```

- Optional: `minLength`, `maxLength`
- JSON encoding: `{ "$bytes": "<base64-string>" }`
- CBOR encoding: byte string (major type 2)

### cid-link

```json
{ "type": "cid-link" }
```

- No type-specific constraint fields
- JSON encoding: `{ "$link": "bafyrei..." }`
- CBOR encoding: CID tag 42
- CID must be version 1, SHA-256 hash

### blob

```json
{
  "type": "blob",
  "accept": ["image/png", "image/*"],
  "maxSize": 1000000
}
```

- Optional: `accept` (MIME type array, glob patterns like `image/*`), `maxSize` (bytes)
- Encoded as: `{ "$type": "blob", "ref": { "$link": "..." }, "mimeType": "image/png", "size": 12345 }`

## Container Types

### array

```json
{
  "type": "array",
  "items": { "type": "string", "format": "at-uri" },
  "maxLength": 50
}
```

- `items` (required): schema for array elements (homogeneous)
- Optional: `minLength`, `maxLength`

### object

```json
{
  "type": "object",
  "required": ["did", "handle"],
  "nullable": ["displayName"],
  "properties": {
    "did": { "type": "string", "format": "did" },
    "handle": { "type": "string", "format": "handle" },
    "displayName": { "type": "string", "maxGraphemes": 64 }
  }
}
```

- `properties` (required): map of field name → schema
- `required` (optional): array of field names that must be present
- `nullable` (optional): array of field names that may be `null`

### params

HTTP query parameter schema (limited scope — used only in `query`, `procedure`, `subscription`).

```json
{
  "type": "params",
  "required": ["actor"],
  "properties": {
    "actor": { "type": "string", "format": "at-identifier" },
    "limit": { "type": "integer", "minimum": 1, "maximum": 100, "default": 50 }
  }
}
```

- Properties limited to: `boolean`, `integer`, `string`, or arrays of these primitive types
- No `nullable` field (unlike `object`)

## Meta Types

### token

Named symbolic value — acts as a constant identifier, not a data container.

```json
{
  "defs": {
    "mention": {
      "type": "token",
      "description": "A mention of another user"
    }
  }
}
```

- Used as values in `knownValues` arrays (e.g. `"com.example.defs#mention"`)
- Cannot be referenced via `ref` or `union`
- No data representation; definition-only

### ref

Schema reuse — points to another definition.

```json
{ "type": "ref", "ref": "#profileView" }
{ "type": "ref", "ref": "com.example.defs#thing" }
```

- Local reference: `#definitionName`
- Global reference: `nsid#definitionName` or just `nsid` (implies `#main`)
- When referencing an `object`, the `$type` field is omitted in encoded data
- Cannot point to `token` type; cannot reference another `ref`

### union

Discriminated union of object/record types.

```json
{
  "type": "union",
  "refs": [
    "app.bsky.embed.images",
    "app.bsky.embed.external",
    "app.bsky.embed.record"
  ],
  "closed": false
}
```

- `refs` (required): array of definition references
- `closed` (optional, default `false`): when false, unknown types are tolerated (forward-compatible)
- All variants must be `object` or `record` types
- All variants require a `$type` discriminator field in encoded data
- Empty closed union is invalid
- Prefer open unions for extensibility

### unknown

Accepts any valid data model value.

```json
{ "type": "unknown" }
```

- Optional `$type` field allowed but not required
- Nested compound types (blobs, CID links) validated per data model rules
- Not recommended in `record` objects — use sparingly

## String Format Values

| Format | Description | Example |
|---|---|---|
| `at-identifier` | DID or handle | `did:plc:abc123` or `alice.bsky.social` |
| `at-uri` | AT URI | `at://did:plc:abc123/app.bsky.feed.post/3k...` |
| `cid` | Content ID string | `bafyrei...` |
| `datetime` | RFC 3339 timestamp | `2024-01-15T12:00:00.000Z` |
| `did` | DID identifier | `did:plc:abc123` |
| `handle` | Handle identifier | `alice.bsky.social` |
| `nsid` | Namespaced identifier | `app.bsky.feed.post` |
| `tid` | Timestamp identifier | `3k2la7bx2nc2u` |
| `record-key` | Record key syntax | `self`, `3k2la7bx2nc2u` |
| `uri` | Generic URI (≤8KB) | `https://example.com` |
| `language` | BCP 47 language tag | `en`, `pt-BR` |

### Datetime Rules

- Uppercase `T` separator required
- Timezone required — prefer UTC `Z` suffix (uppercase only)
- Minimum precision: whole seconds; fractional seconds allowed
- Valid: `1985-04-12T23:20:50.123Z`, `1985-04-12T23:20:50.123456Z`
- Invalid: lowercase `t`/`z`, missing timezone, non-zero-padded values

## $type Field Rules

| Context | $type Required? |
|---|---|
| `record` objects | Always (self-describing) |
| `union` variants | Always (discriminator) |
| Top-level subscription messages | Not required |
| `ref` to `object` | Omitted (type known from context) |
| Main definitions | Use NSID only (no `#main` suffix) |

## Validation Modes

Three modes when creating/updating records:

1. **Explicit validation required** — must validate against known Lexicon; reject if unknown
2. **Explicit no validation** — skip Lexicon validation (data model rules still apply)
3. **Optimistic validation** (default) — validate if Lexicon known, allow if unknown

Unexpected fields produce warnings, not errors. Implementations should preserve unknown fields for forward compatibility.
