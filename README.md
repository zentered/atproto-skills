# atproto-skills

A [Claude Code](https://claude.ai/code) plugin with skills for building on the [AT Protocol](https://atproto.com/) (Bluesky).

## Skills

### atproto-domain

AT Protocol fundamentals — identity resolution, DIDs, handle lookups, PDS discovery, XRPC endpoints, and scopes.

Triggers on: "resolve a Bluesky handle", "look up a DID", "find a PDS endpoint", "how does ATProto identity work", etc.

### atproto-lexicon

Lexicon schema language — schema structure, type system, NSID naming, record types, XRPC endpoints, evolution rules, publishing, and codegen (`goat`, `@atproto/lex`).

Triggers on: "define a lexicon", "create a lexicon schema", "design an XRPC endpoint", "generate types from a lexicon", "publish a lexicon", "how do lexicon types work", etc.

### atproto-oauth

OAuth implementation guide — PAR, DPoP, PKCE, client metadata, token exchange, and common pitfalls (including the base64url padding trap).

Triggers on: "implement ATProto OAuth", "add Bluesky login", "debug DPoP proofs", "fix ATProto OAuth errors", etc.

## Install

From your terminal:

```bash
claude plugin marketplace add https://github.com/zentered/atproto-skills
```

```bash
claude plugin install atproto-skills
```

Or from within a Claude Code session:

```
/plugins marketplace add https://github.com/zentered/atproto-skills
```

```
/plugins install atproto-skills
```

## Evals

### Trigger Accuracy

30 test prompts evaluated against skill descriptions to verify correct skill triggers. See [`tests/trigger-evals.yaml`](tests/trigger-evals.yaml) for cases and [`tests/trigger-eval-results.md`](tests/trigger-eval-results.md) for full results.

| Skill | Cases | Pass Rate |
|-------|-------|-----------|
| atproto-oauth | 10 | 100% |
| atproto-domain | 10 | 100% |
| atproto-lexicon | 10 | 100% |
| **Total** | **30** | **100%** |

### Quality — With Skills vs Without

6 prompts answered by a baseline LLM (no skills) then compared against skill content. Measures whether skills prevent real developer harm. See [`tests/quality-eval-results.md`](tests/quality-eval-results.md) for full analysis.

| Prompt | Skill | Risk Without Skill | Key Gap |
|--------|-------|--------------------|---------|
| "required a client_assertion" error | atproto-oauth | **HIGH** | Misdiagnoses — real issue is base64url padding |
| Local dev OAuth setup | atproto-oauth | **HIGH** | Recommends ngrok; wrong `client_id` format |
| Handle→DID in CF Workers | atproto-domain | **HIGH** | cloudflare-dns.com unreachable in Workers |
| Store handles or DIDs? | atproto-domain | LOW | Baseline gets it right |
| enum vs knownValues | atproto-lexicon | LOW-MED | Directionally correct, soft on breaking contract |
| Publishing a lexicon | atproto-lexicon | **HIGH** | Wrong model — no path to publication |

**4 of 6 prompts are high-risk without skills (67%)** — the skills prevent real debugging dead-ends and broken implementations.

Last evaluated: 2026-03-30 with claude-sonnet-4-6.

## Contributing

Add a new skill:

1. `mkdir -p skills/skill-name/references`
2. Write `SKILL.md` with YAML frontmatter (`name`, `description` with trigger phrases)
3. Keep the body under 3,000 words — move details to `references/`
4. Add trigger eval cases to `tests/trigger-evals.yaml`
5. Run `./tests/validate-skills.sh` to verify

## License

MIT

---

Built by [Zentered](https://zentered.co)
