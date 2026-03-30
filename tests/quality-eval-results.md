# Quality Eval Results — With Skills vs Without

Last run: 2026-03-30
Model: claude-sonnet-4-6
Purpose: Measure whether the skills prevent real developer harm compared to baseline LLM knowledge.

## Methodology

6 prompts (2 per skill) were answered by a baseline LLM with no skill content, then compared against the authoritative skill content. Each is rated by risk level: would the baseline lead the user astray?

## Results

| # | Prompt | Skill | Risk Without Skill | Key Gap |
|---|--------|-------|--------------------|---------|
| P1 | "required a client_assertion" error | atproto-oauth | **HIGH** | Misdiagnoses cause — real issue is base64url padding, not missing assertion |
| P2 | Local dev OAuth setup | atproto-oauth | **HIGH** | Recommends ngrok (unnecessary); wrong `client_id` format |
| P3 | Handle→DID in Cloudflare Workers | atproto-domain | **HIGH** | Recommends cloudflare-dns.com which is unreachable in Workers |
| P4 | Store handles or DIDs? | atproto-domain | **LOW** | Gets conclusion right; misses permanence guarantee details |
| P5 | enum vs knownValues | atproto-lexicon | **LOW-MED** | Directionally correct but soft on compatibility contract |
| P6 | Publishing a custom lexicon | atproto-lexicon | **HIGH** | Wrong model — describes URL hosting; real path is `goat` CLI |

**4 of 6 high-risk without skills (67%)**

## Detailed Analysis

### P1: "I'm getting 'required a client_assertion' from bsky.social — what's wrong?"

**Without skill:** Advises adding or reconfiguring the `client_assertion` parameter — a complete misdiagnosis. The developer would chase the wrong problem.

**With skill:** Identifies the real cause: base64url padding (`=` chars) in the JWT. The bsky.social Zod schema silently rejects padded JWTs, falling through to `none` type, producing this misleading error. Fix: use unpadded base64url encoding.

**Impact:** Hours of debugging saved. The error message is actively misleading and untraceable without this knowledge.

### P2: "How do I set up OAuth for local development against Bluesky?"

**Without skill:** Recommends ngrok tunneling, HTTPS redirect URIs, and registering a client — all wrong for ATProto.

**With skill:** `client_id` must be exactly `http://localhost` (no port, HTTP not HTTPS, not `127.0.0.1`). No ngrok needed — the auth server generates virtual client metadata. Config goes in query params on the `client_id`. Cookie flags: `secure: false`, `sameSite: 'lax'`. Watch for hot-reload wiping session state.

**Impact:** Eliminates a broken setup path. Ngrok adds complexity and still wouldn't work because `client_id` format rules are strict.

### P3: "I'm building a Bluesky bot in Cloudflare Workers — how do I resolve a handle to a DID?"

**Without skill:** Recommends DNS-over-HTTPS via `cloudflare-dns.com` — which is unreachable from within Cloudflare Workers.

**With skill:** Use the Bluesky API (`com.atproto.identity.resolveHandle`) as the primary method. DNS-over-HTTPS fails silently in Workers. Three resolution methods exist with clear priority order.

**Impact:** Prevents a silent failure that's nearly impossible to debug without knowing the Workers restriction.

### P4: "Should I store user handles or DIDs in my database?"

**Without skill:** Correctly recommends DIDs as primary key. Handles are secondary/display-only.

**With skill:** Adds depth — DIDs persist across PDS migrations, handles must be stripped of `@` and lowercased, any stored handle may be stale.

**Impact:** Low — baseline intuition aligns with the correct answer here.

### P5: "Should I use enum or knownValues in my lexicon schema?"

**Without skill:** Gets the direction right (knownValues for extensibility) but undersells the consequences. Frames enum breakage as a choice rather than a hard constraint.

**With skill:** Clear default: prefer `knownValues`. Adding an `enum` value IS a breaking change — existing clients reject unknown values. Use `goat lex diff` to enforce.

**Impact:** Low-medium — a careful developer would be fine, but the skill prevents a common "enum feels cleaner" mistake.

### P6: "How do I publish a custom lexicon to the AT Protocol network?"

**Without skill:** Describes hosting lexicon files at URLs — a fundamentally wrong model.

**With skill:** Lexicons are published as `com.atproto.lexicon.schema` records via the `goat` CLI (`goat lex publish`). DNS TXT record at `_lexicon.<reversed-authority>` with `did=<DID>` establishes NSID authority.

**Impact:** Without the skill, there's no working path to publication. The correct mechanism has no analogue in general web dev.

## Observations

The high-risk cases share a pattern: **ATProto-specific constraints that are counterintuitive or undocumented in general LLM training data.**

- P1: A Zod validation quirk produces a misleading error message
- P2: localhost exception rules with strict `client_id` format
- P3: An environment-specific DNS restriction
- P6: A novel publishing model via repository records

The low-risk cases (P4, P5) succeed because general software engineering intuition ("use stable IDs", "prefer extensible types") happens to align with ATProto's design.

## How to Re-run

Write baseline responses for the prompts without skill content loaded, then compare against the skill SKILL.md files. Judge risk as: would a developer following the baseline waste significant time or build something broken?
