# Trigger Eval Results

Last run: 2026-03-30
Model: claude-sonnet-4-6
Result: **30/30 pass (100%)**

| # | Prompt | Expected | Predicted | Result | Notes |
|---|--------|----------|-----------|--------|-------|
| 1 | help me implement Bluesky OAuth login | atproto-oauth | atproto-oauth | pass | |
| 2 | I'm getting a DPoP nonce error from bsky.social | atproto-oauth | atproto-oauth | pass | |
| 3 | how do I set up PAR for ATProto? | atproto-oauth | atproto-oauth | pass | |
| 4 | debug my ATProto token exchange — getting 'required a client_assertion' | atproto-oauth | atproto-oauth | pass | |
| 5 | configure PKCE for my Bluesky app | atproto-oauth | atproto-oauth | pass | |
| 6 | set up client metadata for ATProto OAuth | atproto-oauth | atproto-oauth | pass | |
| 7 | my refresh token keeps getting invalidated | atproto-oauth | atproto-oauth | pass | |
| 8 | how do I make DPoP proofs for resource requests? | atproto-oauth | atproto-oauth | pass | |
| 9 | what scopes do I need for Bluesky DMs? | atproto-domain | atproto-domain | pass | |
| 10 | add Bluesky login to my SvelteKit app | atproto-oauth | atproto-oauth | pass | |
| 11 | resolve a Bluesky handle to a DID | atproto-domain | atproto-domain | pass | |
| 12 | how does ATProto identity work? | atproto-domain | atproto-domain | pass | |
| 13 | look up the PDS endpoint for a user | atproto-domain | atproto-domain | pass | |
| 14 | what's the difference between did:plc and did:web? | atproto-domain | atproto-domain | pass | |
| 15 | how do I call XRPC endpoints on Bluesky? | atproto-domain | atproto-domain | pass | |
| 16 | discover the auth server for a self-hosted PDS | atproto-domain | atproto-domain | pass | "discover an auth server" is verbatim trigger |
| 17 | what ATProto scopes are available? | atproto-domain | atproto-domain | pass | |
| 18 | how do I get a user's profile from the Bluesky API? | atproto-domain | atproto-domain | pass | |
| 19 | how do I define a new lexicon for my app? | atproto-lexicon | atproto-lexicon | pass | |
| 20 | create a record type for my custom data | atproto-lexicon | atproto-lexicon | pass | |
| 21 | what types are available in lexicon schemas? | atproto-lexicon | atproto-lexicon | pass | |
| 22 | publish my lexicon to the AT Protocol network | atproto-lexicon | atproto-lexicon | pass | |
| 23 | generate TypeScript types from lexicon schemas | atproto-lexicon | atproto-lexicon | pass | |
| 24 | should I use enum or knownValues in my lexicon? | atproto-lexicon | atproto-lexicon | pass | |
| 25 | design an XRPC query endpoint with pagination | atproto-lexicon | atproto-lexicon | pass | "design an XRPC endpoint" is a lexicon trigger |
| 26 | how do lexicon evolution rules work? | atproto-lexicon | atproto-lexicon | pass | |
| 27 | install lexicons with @atproto/lex | atproto-lexicon | atproto-lexicon | pass | |
| 28 | what NSID naming conventions should I follow? | atproto-lexicon | atproto-lexicon | pass | |
| 29 | build a Bluesky bot that posts automatically | atproto-domain | atproto-domain | pass | "create a Bluesky bot" is verbatim trigger; OAuth is downstream |
| 30 | authenticate with Bluesky from Cloudflare Workers | atproto-oauth | atproto-oauth | pass | "authenticate with Bluesky" is verbatim trigger |

## Ambiguous Cases

Cases 29 and 30 are intentionally ambiguous — multiple skills could reasonably apply. The expected values reflect which skill should load *first* based on the primary intent.

## How to Re-run

Feed `tests/trigger-evals.yaml` cases and all three skill descriptions to an LLM judge. Compare predicted vs expected skill for each prompt.
