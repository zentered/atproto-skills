---
name: atproto-domain
description: This skill should be used when the user asks to "resolve a Bluesky handle", "look up a DID", "find a PDS endpoint", "discover an auth server", "work with ATProto identity", "query XRPC endpoints", "what is did:plc vs did:web", "get a user's profile", or mentions AT Protocol architecture, DID documents, handle resolution, PDS discovery, plc.directory, ATProto scopes, XRPC NSIDs, or Bluesky API structure. Covers identity, discovery, and API fundamentals — not OAuth flows (see atproto-oauth for authentication).
---

# AT Protocol Domain Knowledge

The AT Protocol (ATProto) is a decentralized social networking protocol. Bluesky (`bsky.social`) is the largest network built on it. This skill covers the identity layer, discovery mechanisms, and protocol fundamentals that underpin all ATProto integrations.

## Identity System

ATProto identity has three layers: **handles** (human-readable), **DIDs** (persistent identifiers), and **DID documents** (service discovery).

```
Handle (alice.bsky.social)
  → DID (did:plc:abc123)
    → DID Document
      → PDS endpoint (https://morel.us-east.host.bsky.network)
        → Auth server, data, XRPC endpoints
```

### Handles

- Domain-based identifiers (e.g. `alice.bsky.social`, `alice.com`)
- Mutable — users can change handles without changing DID
- Always strip `@` prefix and lowercase before resolution
- Custom domain handles prove domain ownership

### DIDs

Two DID methods in use:
- **`did:plc`** — most common, resolved via `plc.directory` (e.g. `https://plc.directory/did:plc:abc123`)
- **`did:web`** — resolved via `https://{domain}/.well-known/did.json`

DIDs are the stable, permanent identifier. Always store DIDs, not handles, as the canonical user reference.

### DID Documents

Contain service endpoints and verification keys. The `#atproto_pds` service entry points to the user's Personal Data Server (PDS). Extract it with:

```
did_doc.service.find(s => s.id === "#atproto_pds").serviceEndpoint
```

For full DID document examples (`did:plc` and `did:web`), see **`references/did-document-examples.md`**.

## Handle Resolution

Three methods, in priority order:

1. **Bluesky API** — `GET https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle={handle}` — works everywhere, use as primary
2. **DNS TXT** — `_atproto.{handle}` via DNS-over-HTTPS — fails from Cloudflare Workers (`cloudflare-dns.com` unreachable from within Workers)
3. **HTTP well-known** — `GET https://{handle}/.well-known/atproto-did` — fails for DNS-based custom domain handles

For most implementations, method 1 is sufficient. Use methods 2-3 as fallbacks for self-hosted or offline-first scenarios.

## PDS and Auth Server Discovery

### PDS Discovery

From a DID document, extract the `#atproto_pds` service endpoint. This is the user's PDS.

### Auth Server Discovery

Two-step discovery from the PDS:

```
GET {pds}/.well-known/oauth-protected-resource
→ { "authorization_servers": ["https://bsky.social"] }

GET {auth_server}/.well-known/oauth-authorization-server
→ { authorization_endpoint, token_endpoint, pushed_authorization_request_endpoint, ... }
```

Always discover dynamically — ATProto is decentralized. Self-hosted PDS instances use different auth servers. Never hardcode `bsky.social` as the auth server.

## XRPC

ATProto APIs use XRPC (Cross-Reference Procedure Call):
- **Queries** — `GET /xrpc/{nsid}?params` (read operations)
- **Procedures** — `POST /xrpc/{nsid}` with JSON body (write operations)
- NSIDs use reverse-DNS notation: `com.atproto.identity.resolveHandle`, `app.bsky.feed.getTimeline`

### Key Public Endpoints

These work without authentication via `public.api.bsky.app`:
- `com.atproto.identity.resolveHandle` — handle → DID
- `app.bsky.actor.getProfile` — public profile data
- `app.bsky.feed.getAuthorFeed` — public posts

### Authenticated Endpoints

Require OAuth tokens, sent to the user's PDS:
- `com.atproto.repo.createRecord` — create posts, likes, follows
- `com.atproto.repo.deleteRecord` — delete records
- `app.bsky.feed.getTimeline` — authenticated timeline
- `app.bsky.notification.listNotifications` — notifications

## Scopes

ATProto OAuth scopes control access levels:

- `atproto` — mandatory for all sessions
- `transition:generic` — broad PDS read/write (equivalent to legacy App Passwords; temporary until granular scopes ship)
- `transition:chat.bsky` — DM access (requires `transition:generic`)
- `transition:email` — account email access

The `transition:` prefix indicates these are temporary scopes that will be replaced by fine-grained permissions.

## Common Pitfalls

1. **Hardcoding `bsky.social`** — ATProto is decentralized. Always discover the PDS and auth server dynamically from the user's DID.
2. **Storing handles as identifiers** — handles change. Store DIDs as the canonical reference.
3. **Cloudflare Workers DNS** — `cloudflare-dns.com` is unreachable from within Workers. Use the Bluesky API for handle resolution instead of DNS-over-HTTPS.
4. **Missing `@` strip** — handles entered by users often include `@` prefix. Always strip and lowercase.
5. **Assuming PDS = API** — public API (`public.api.bsky.app`) is for unauthenticated reads. Authenticated requests go to the user's PDS endpoint from their DID document.

## Additional Resources

### Reference Files

- **`references/did-document-examples.md`** — Full DID document examples for `did:plc` and `did:web`, verification method structures, and service endpoint formats
