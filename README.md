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
