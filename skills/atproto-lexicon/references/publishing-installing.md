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

### DNS Resolution for Authority

Lexicon authority is rooted in DNS domain control. To associate an NSID namespace with a DID:

Create a TXT record: `_lexicon.<reversed-authority>` containing `did=<DID>`

Example for NSID `dev.myapp.thing`:
- DNS name: `_lexicon.thing.myapp.dev`
- TXT value: `did=did:plc:abc123`

Resolution is non-hierarchical — no recursion up or down the DNS hierarchy.

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
