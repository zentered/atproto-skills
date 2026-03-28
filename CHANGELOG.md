# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **atproto-lexicon**: new skill covering the Lexicon schema language — type system, NSID naming, schema structure, evolution rules, publishing with goat, codegen with @atproto/lex
- **atproto-domain**: federation architecture section (PDS, Relay, App View, Feed Generator, Labeler)
- **atproto-domain**: data model section (repositories, records, collections, lexicons, AT URIs, blobs)
- **atproto-domain**: SDK quickstart (TypeScript, Python, Dart)
- **atproto-domain**: authentication overview (app passwords vs OAuth)
- **atproto-domain**: account portability (signing key, recovery key, migration)
- **atproto-domain**: new reference file `references/federation-architecture.md`
- **atproto-oauth**: localhost development section with full rules (no ngrok needed)
- **atproto-oauth**: common localhost pitfalls (hostname mismatch, hot reload, cookie flags)
- **atproto-oauth**: DPoP note — `iss` should not be included in PDS resource request JWTs

### Fixed

- **atproto-oauth**: removed incorrect claim that ngrok is required for local development
- **atproto-oauth**: removed incorrect claim that auth server must reach client metadata URL (localhost uses virtual metadata)
- **atproto-oauth**: scoped pitfall #11 (client metadata unreachable) to production clients only

## [0.1.0] - 2025-03-15

### Added

- Initial plugin with `atproto-domain` and `atproto-oauth` skills
- Identity resolution: handles, DIDs (`did:plc`, `did:web`), DID documents, PDS discovery
- XRPC endpoint reference (public and authenticated)
- OAuth flow: PAR, DPoP, PKCE, client metadata, token exchange
- Common pitfalls for both skills
- Trigger eval test suite
- Plugin marketplace support
