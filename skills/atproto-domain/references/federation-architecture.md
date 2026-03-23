# Federation Architecture

## Overview

The AT Protocol network is composed of independent services that communicate over standard HTTP and WebSocket protocols. The architecture separates concerns: data hosting, aggregation, application logic, algorithms, and moderation are each handled by different service types that anyone can operate.

## Personal Data Server (PDS)

The PDS is the user's agent in the network. Responsibilities:

- **Hosts user repositories** — all records (posts, likes, follows) live here as signed Merkle trees
- **Manages authentication** — login, session management, OAuth authorization
- **Controls signing keys** — signs repo commits on behalf of the user
- **Stores private data** — muted accounts, preferences, data not included in public repos
- **Proxies service requests** — forwards authenticated requests to App Views and other services

The PDS design is intentionally lightweight to make self-hosting practical. Heavy indexing and aggregation are offloaded to Relays and App Views.

### Self-Hosting

Run a PDS using the official distribution: https://github.com/bluesky-social/pds

Self-hosted PDS instances participate in the federated network. The Relay crawls them like any other PDS. Users on self-hosted PDSes appear identically to users on `bsky.network`.

## Relay (Big Graph Service)

The Relay crawls all known PDSes and consolidates updates into a unified event stream (the "firehose"). Downstream services subscribe to this stream instead of crawling PDSes individually.

Characteristics:
- Resource-intensive — must process the entire network
- Emits a real-time WebSocket stream of repo operations
- Multiple Relays can coexist: large full-network Relays alongside smaller specialized ones
- Downstream consumers (App Views, Feed Generators) subscribe via `com.atproto.sync.subscribeRepos`

The firehose is an ordered stream of commit events containing the repo operations (creates, updates, deletes) across all accounts.

## App View

App Views consume the firehose and build domain-specific APIs. They are semantically aware — they understand the lexicon schemas and build indexes, metrics (like counts, repost counts), and query endpoints.

- The Bluesky App View implements the `app.bsky.*` lexicon for microblogging
- New applications define their own lexicons and deploy corresponding App Views
- Multiple App Views can coexist for different application domains (video, long-form, groups)
- The public API at `public.api.bsky.app` is the Bluesky App View's public read endpoint

App Views are analogous to a prism: they take the Relay's raw firehose data and refract it into structured, queryable application data.

## Feed Generator

Feed Generators produce custom algorithmic feeds. They receive data from the firehose (or App View APIs), apply ranking/filtering logic, and return ordered lists of post URIs.

- Registered as services in the network
- Users can select which Feed Generators to subscribe to
- Third parties can operate Feed Generators without running a full PDS or App View
- Declared via the `app.bsky.feed.generator` record type

## Labeler

Labelers apply moderation and content labels to accounts and records. Labels inform client-side display decisions (warnings, content hiding, age-gating).

- Bluesky operates the default moderation labeler
- Third parties can run custom labelers for community-specific moderation
- Clients can subscribe to multiple labelers
- Labels are advisory — the client decides how to display labeled content

## Data Flow

```
User Action
  → PDS (stores in repo, signs commit)
    → Relay (crawls PDS, emits to firehose)
      → App View (indexes, builds API)
        → Client (reads via XRPC)

Feed Generator ← subscribes to firehose or App View
Labeler ← subscribes to firehose, emits labels
```

## Big World / Small World

The architecture follows a "big world with small world fallbacks" philosophy:

- **Big world** (default): Relays aggregate the entire network, App Views build global indexes. Content is discoverable beyond immediate social connections.
- **Small world** (fallback): Direct PDS-to-PDS communication is possible for targeted queries. Self-hosted communities can operate without relying on large Relays.

This design reduces load on individual PDSes (enabling practical self-hosting) while maintaining broad content discoverability.
