---
name: atproto-lexicon
description: This skill should be used when the user asks to "define a lexicon", "create a lexicon schema", "write a record type", "design an XRPC endpoint", "publish a lexicon", "install a lexicon", "generate types from a lexicon", "validate a lexicon", "add a query endpoint", "add a procedure endpoint", "what is a lexicon", "how do lexicon types work", "use goat to publish", "use @atproto/lex", or mentions NSID naming, lexicon evolution rules, ATProto schema design, record key types, lexicon style guide, knownValues vs enum, open vs closed unions, or lexicon codegen. Covers schema definition, type system, naming conventions, publishing, and installation — for identity and OAuth, see atproto-domain and atproto-oauth.
---

# ATProto Lexicons

Lexicons are the schema language of the AT Protocol. They define XRPC endpoints (queries, procedures, subscriptions) and repository record types using a JSON-based format similar to JSON Schema. Every API call and every record stored in a user's repository conforms to a lexicon.

Lexicons enable interoperability — any client that understands a lexicon can work with any server implementing it. Custom applications define their own lexicons under their own namespace and deploy corresponding App Views.

## Schema Structure

A lexicon file is a JSON object with three required fields:

```json
{
  "lexicon": 1,
  "id": "com.example.thing",
  "defs": {
    "main": {
      "type": "record",
      "key": "tid",
      "record": {
        "type": "object",
        "required": ["name", "createdAt"],
        "properties": {
          "name": { "type": "string", "maxLength": 256 },
          "createdAt": { "type": "string", "format": "datetime" }
        }
      }
    }
  }
}
```

- `lexicon`: always `1` (current version)
- `id`: the NSID (Namespaced Identifier) in reverse-DNS format
- `defs`: map of named definitions; `main` is the primary definition

A file must contain at least one definition. Non-`main` definitions are referenced as `nsid#name`.

## NSIDs

Namespaced Identifiers use reverse-DNS notation to prevent collisions:

- `com.atproto.*` — core protocol (identity, repo, sync, server)
- `app.bsky.*` — Bluesky social app (feed, actor, graph, notification)
- `dev.myapp.*` — custom application namespace

Authority over an NSID namespace is rooted in DNS domain ownership. Register authority via DNS TXT record: `_lexicon.<reversed-authority>` with value `did=<DID>`.

## Primary Definition Types

Five types can serve as a `main` definition:

| Type | Purpose | XRPC Method |
|---|---|---|
| `record` | Data stored in repositories | N/A |
| `query` | Read endpoints | HTTP GET |
| `procedure` | Write endpoints | HTTP POST |
| `subscription` | Event streams | WebSocket |
| `permission-set` | Auth permission bundles | N/A |

### Records

Define the shape of data stored in user repositories:

```json
{
  "type": "record",
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

Records always include a `$type` field in their encoded form, set to the lexicon NSID. The `key` field specifies the record key type (`tid` for timestamp-based, `nsid`, `any`, or a literal value like `"self"`).

### Query and Procedure Endpoints

```json
{
  "type": "query",
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
  "errors": [{ "name": "AccountNotFound" }]
}
```

- `params` properties are limited to primitives: `boolean`, `integer`, `string`, or arrays of these
- Use `at-identifier` format in params to accept both DIDs and handles
- Procedures add an `input` field (same shape as `output`)
- Always specify `output` with `encoding`

## Core Type System

### Primitives

| Type | Key Constraints |
|---|---|
| `boolean` | `default`, `const` |
| `integer` | `minimum`, `maximum`, `enum`, `default` (signed 64-bit; 53-bit recommended for JS) |
| `string` | `format`, `maxLength`, `minLength`, `maxGraphemes`, `minGraphemes`, `enum`, `knownValues` |
| `bytes` | `minLength`, `maxLength` |
| `cid-link` | No constraints (content hash reference) |
| `blob` | `accept` (MIME globs), `maxSize` |

No floating-point type exists — floats produce inconsistent results across architectures during re-encoding.

### Containers

- **`object`** — keyed properties with `required` and `nullable` arrays
- **`array`** — homogeneous items with `minLength`/`maxLength`
- **`params`** — like `object` but limited to primitives (for query parameters)

### References and Unions

**`ref`** — reuse a definition from the same or another lexicon:

```json
{ "type": "ref", "ref": "#localDef" }
{ "type": "ref", "ref": "com.example.defs#sharedType" }
```

**`union`** — discriminated union with `$type` field on each variant:

```json
{
  "type": "union",
  "refs": ["#imageEmbed", "#videoEmbed", "#externalEmbed"],
  "closed": false
}
```

Prefer open unions (`closed: false`, the default) to allow third-party extension. All union variants must be `object` or `record` types.

**`token`** — named symbolic constant, used in `knownValues` arrays. Cannot be referenced via `ref` or `union`.

### knownValues vs enum

- **`enum`**: closed set — adding values is a breaking change
- **`knownValues`**: open set — new values can be added without breaking existing consumers

Prefer `knownValues` for extensibility. Token definitions can serve as `knownValues` entries:

```json
{ "type": "string", "knownValues": ["com.example.defs#public", "com.example.defs#private"] }
```

For the complete type reference, see **`references/type-system.md`**.

## Naming Conventions

| Context | Style | Example |
|---|---|---|
| Schema & field names | `lowerCamelCase` | `getProfile`, `displayName` |
| API error names | `UpperCamelCase` | `AccountNotFound` |
| Fixed strings / known values | `kebab-case` | `content-warning` |
| Records | Singular nouns | `post`, `like`, `profile` |
| Queries | verb + noun | `getPost`, `listLikes` |
| Procedures | verb + noun | `createRecord`, `deleteRecord` |

Fields prefixed with `$` are reserved for the protocol. Application schemas must not define `$`-prefixed fields.

For detailed naming rules and API design patterns, see **`references/style-guide.md`**.

## Evolution Rules

Published lexicons are effectively frozen once adopted by third parties:

- New fields must be optional
- Non-optional fields cannot be removed
- Field types cannot change
- Fields cannot be renamed
- Breaking changes require a new NSID (convention: append `V2`)

Loosening a constraint breaks old validators; tightening breaks new producers. Only optional constraints may be added to previously unconstrained fields.

## Pagination Pattern

Standard cursor-based pagination for list endpoints:

- Parameters: `limit` (integer) + `cursor` (string, optional)
- Response: required results array + optional `cursor`
- Absent `cursor` in response = no more pages
- Cursor values are opaque — do not parse or construct them

## Tooling

### Publishing with goat

```bash
brew install goat
goat lex new record dev.myapp.thing    # scaffold a new lexicon
goat lex lint                           # validate schema structure
goat lex diff                           # check evolution rules
goat lex publish                        # publish to AT Protocol network
```

Authenticate with `goat account login` or `GOAT_USERNAME`/`GOAT_PASSWORD` environment variables. Lexicons are published as `com.atproto.lexicon.schema` records in the user's repository.

### Installing and Codegen with @atproto/lex

```bash
npm install -g @atproto/lex
lex install app.bsky.feed.post app.bsky.feed.like   # download schemas
lex build                                             # generate TypeScript
```

Generated code in `./src/lexicons/` provides type-safe API clients:

```typescript
import { Client } from '@atproto/lex'
import * as app from './lexicons/app.js'

const client = new Client('https://public.api.bsky.app')
const response = await client.call(app.bsky.actor.getProfile, {
  actor: 'pfrazee.com',
})
```

For full tooling details, see **`references/publishing-installing.md`**.

## Common Pitfalls

1. **Closed enums** — use `knownValues` instead of `enum` to allow adding values without breaking consumers.
2. **Required field creep** — marking fields `required` is irreversible. Start optional, promote to required only when certain.
3. **Bare arrays in responses** — wrap items in objects (`{ "items": [{ "uri": "..." }] }`) to allow adding per-item fields later.
4. **Handles in record schemas** — always reference accounts by DID in records. Handles are mutable and belong only in query params (as `at-identifier`).
5. **Missing format on strings** — always specify `format` when a semantic type exists (datetime, DID, handle, AT URI). Omitting it loses validation.
6. **Ignoring evolution rules** — test changes with `goat lex diff` before publishing. A breaking change to a published lexicon requires a new NSID.

## Additional Resources

### Reference Files

- **`references/type-system.md`** — Complete type reference: all field types, container types, meta types, string formats, `$type` rules, validation modes
- **`references/style-guide.md`** — Naming conventions, field design guidelines, pagination pattern, evolution rules, advanced patterns (hydrated views, richtext facets, sidecar records)
- **`references/publishing-installing.md`** — Full `goat` CLI workflow, `@atproto/lex` codegen, TypeScript usage, DNS authority setup
