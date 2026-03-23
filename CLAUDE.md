# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin providing skills for building on the AT Protocol (Bluesky). Installed via `--plugin-dir` or Git URL.

## Testing

```bash
# Run all skill validation tests
./tests/validate-skills.sh
```

Tests check: frontmatter validity, third-person descriptions, trigger phrase count, word count range (500-3000), referenced files exist, no orphaned resources, no second-person writing.

Trigger evals in `tests/trigger-evals.yaml` are reviewed manually or by LLM — no automated runner.

## Architecture

```
.claude-plugin/plugin.json    # Plugin manifest (name, version, tags)
skills/
  atproto-domain/             # AT Protocol fundamentals (identity, DIDs, XRPC)
  atproto-oauth/              # OAuth flow (PAR, DPoP, PKCE, client metadata)
```

Each skill follows progressive disclosure: lean SKILL.md (~500-1500 words) with detailed content in `references/`.

**atproto-domain** covers identity resolution, handle→DID→PDS discovery, XRPC endpoints, and scopes. **atproto-oauth** covers the OAuth flow and assumes identity resolution is handled — it cross-references atproto-domain for prerequisites.

## Changelog

Update `CHANGELOG.md` when making user-facing changes to skills. Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Add entries under `[Unreleased]` with the skill name in bold as prefix (e.g. `- **atproto-oauth**: fixed localhost instructions`). Categories: Added, Changed, Fixed, Removed.

## Adding a New Skill

1. `mkdir -p skills/skill-name/references`
2. Write `SKILL.md` with YAML frontmatter (`name`, `description` in third-person with trigger phrases)
3. Keep body under 3000 words; move detailed content to `references/`
4. Run `./tests/validate-skills.sh` to verify
5. Add trigger eval cases to `tests/trigger-evals.yaml`
