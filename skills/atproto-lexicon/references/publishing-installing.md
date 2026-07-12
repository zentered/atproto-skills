# Publishing and Installing Lexicons

Tools and workflows for creating, publishing, and consuming AT Protocol lexicons.

## Publishing with goat

`goat` is the official CLI for managing lexicons on the AT Protocol network.

### Installation

```bash
brew install goat
```

### Workflow

**1. Pull existing reference lexicons:**

Download lexicon JSON files into `./lexicons/` for local reference or cross-referencing:

```bash
goat lex pull com.atproto.repo.strongRef com.atproto.moderation.defs app.bsky.actor.profile
```

**2. Create a new lexicon:**

Generate a scaffolded lexicon file:

```bash
goat lex new record dev.myapp.thing
```

This creates `./lexicons/dev/myapp/thing.json` with a skeleton `record` definition. Edit the file to define the schema.

Other creation commands by type:

```bash
goat lex new query dev.myapp.getThing
goat lex new procedure dev.myapp.createThing
```

**3. Lint and verify:**

```bash
goat lex lint
goat lex diff
```

`goat lex lint` validates schema structure. `goat lex diff` shows changes relative to the published version and checks evolution rules (no breaking changes).

**4. Publish to the network:**

```bash
goat lex publish
```

Lexicons are published as `com.atproto.lexicon.schema` records in the authenticated user's AT Protocol repository.

### Authentication

Publishing requires authentication. Authenticate via:

```bash
goat account login
```

Or set environment variables:

```bash
export GOAT_USERNAME="handle.example.com"
export GOAT_PASSWORD="app-password-here"
```

### Publishing manually (without goat)

`goat lex publish` is a convenience wrapper. A `com.atproto.lexicon.schema`
record is an ordinary repo record, so you can publish one directly with
`com.atproto.repo.putRecord`, which is handy for a one-off script or a CI step.

Two rules the record must follow:

- **rkey is the full NSID.** The record is stored at rkey `dev.myapp.thing`, not
  `main` and not a TID.
- **`$type` is `com.atproto.lexicon.schema`**, and the lexicon body (`lexicon: 1`,
  `id`, `defs`) is nested inside `record`.

putRecord body:

```json
{
  "repo": "did:plc:abc123",
  "collection": "com.atproto.lexicon.schema",
  "rkey": "dev.myapp.thing",
  "record": {
    "$type": "com.atproto.lexicon.schema",
    "lexicon": 1,
    "id": "dev.myapp.thing",
    "defs": { "main": { "type": "record", "key": "self", "record": { "...": "..." } } }
  }
}
```

Authoring the record needs an authenticated session for the **authority account**
(the DID the `_lexicon` TXT points at), not an end-user session. The `key` inside
`defs.main` must match how the app actually writes records: `literal:self` when
records live at rkey `self`, or `tid` for timestamp keys.

### DNS Resolution for Authority

Lexicon authority is rooted in DNS domain control. An NSID splits into a **domain
authority** (every segment except the last) and a **name** (the last segment).
Authority is registered against the domain authority only; the name segment is
dropped.

To associate an NSID's authority with a DID, create a TXT record at
`_lexicon.<domain-authority>` containing `did=<DID>`.

Example for NSID `dev.myapp.thing`:
- domain authority: `myapp.dev` (not `thing.myapp.dev`, since `thing` is the name)
- name: `thing`
- DNS name: `_lexicon.myapp.dev`
- TXT value: `did=did:plc:abc123`

Every lexicon sharing a domain authority (`dev.myapp.thing`, `dev.myapp.other`)
resolves through the **same** `_lexicon.myapp.dev` record. Resolution is
non-hierarchical: no recursion up or down the DNS hierarchy.

### Verifying resolution

A resolver walks: NSID to domain authority, `_lexicon.<authority>` TXT to a DID,
resolve that DID's PDS, then fetch the `com.atproto.lexicon.schema` record at
rkey = NSID. Two checks confirm both halves are in place:

```bash
# 1. DNS authority resolves to the schema-holder DID
dig +short TXT _lexicon.myapp.dev
#   "did=did:plc:abc123"

# 2. The schema record exists at rkey = the full NSID
curl -s "<pds>/xrpc/com.atproto.repo.getRecord?repo=did:plc:abc123\
&collection=com.atproto.lexicon.schema&rkey=dev.myapp.thing"
```

If the TXT record is missing or the rkey is wrong, inspectors (such as pds.ls)
report `failed to resolve lexicon authority; nsid=<nsid>`.

## Installing with @atproto/lex

`@atproto/lex` provides lexicon installation and TypeScript code generation.

### Installation

```bash
npm install -g @atproto/lex
```

### Install Lexicons Locally

```bash
lex install app.bsky.feed.post app.bsky.feed.like
```

This creates:
- `lexicons.json` — manifest tracking installed lexicons and their versions (identified by CIDs)
- `lexicons/` directory — the actual lexicon JSON schema files

### Code Generation

Generate type-safe TypeScript from installed lexicons:

```bash
lex build
```

Output goes to `./src/lexicons/` with type definitions and validation helpers.

### TypeScript Usage

```typescript
import { Client } from '@atproto/lex'
import * as app from './lexicons/app.js'

const client = new Client('https://public.api.bsky.app')

// Type-safe API call — parameters and response are fully typed
const response = await client.call(app.bsky.actor.getProfile, {
  actor: 'pfrazee.com',
})

console.log(response.displayName)
```

The generated code enforces parameter types and validates responses against the lexicon schemas at compile time.

## Lexicon File Structure

Whether created manually or via `goat`, lexicon files follow this structure:

```json
{
  "lexicon": 1,
  "id": "dev.myapp.thing",
  "description": "A thing in my app",
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

Fields:
- `lexicon` (required): always `1` (current version)
- `id` (required): NSID matching the file path
- `description` (optional): brief overview
- `defs` (required): map of named definitions; `main` describes the primary type

## Cross-Referencing Lexicons

Reference definitions from other lexicons using full NSID paths:

```json
{
  "type": "ref",
  "ref": "com.atproto.repo.strongRef"
}
```

Or reference a specific definition within a lexicon:

```json
{
  "type": "ref",
  "ref": "app.bsky.feed.defs#postView"
}
```

Pull referenced lexicons locally with `goat lex pull` to enable validation and code generation.
