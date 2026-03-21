---
name: atproto-oauth
description: This skill should be used when the user asks to "implement ATProto OAuth", "add Bluesky login", "debug DPoP proofs", "set up PAR", "configure PKCE for ATProto", "fix ATProto OAuth errors", "set up client metadata", "debug token exchange", or mentions DPoP nonce issues, pushed authorization requests, client assertions, ATProto token refresh, or OAuth for Bluesky/AT Protocol apps. For identity resolution and handle lookups without OAuth, see atproto-domain instead.
---

# ATProto OAuth

ATProto uses OAuth 2.0 Authorization Code flow with three mandatory extensions: **PAR** (Pushed Authorization Requests), **DPoP** (Demonstration of Proof-of-Possession), and **PKCE** (S256 only). There is no client registration — clients publish metadata at a URL, and that URL *is* the `client_id`.

Generic OAuth libraries will not work. Mandatory DPoP, PAR, decentralized discovery, and metadata-as-registration require custom implementation.

## Prerequisites

Identity resolution (handle → DID → PDS → auth server) is covered by the **atproto-domain** skill. This skill starts after the auth server has been discovered.

## The Flow

```
[Identity Resolution → Auth Server Discovery] → PKCE → DPoP → PAR → User Auth → Callback → Token Exchange → Resource Requests
 ↑ See atproto-domain skill
```

### 1. PKCE

- Generate code verifier: 32 random bytes, base64url-encoded (unpadded)
- S256 challenge: SHA-256 hash of verifier, base64url-encoded (unpadded)
- S256 is the **only** supported challenge method

### 2. DPoP Key Pair

Generate a fresh ES256 (P-256 ECDSA) key pair per session. This binds tokens to the client instance.

**DPoP proof JWT structure:**
```
Header: { typ: "dpop+jwt", alg: "ES256", jwk: { kty, crv, x, y } }
Payload: { jti: <uuid>, htm: <HTTP method>, htu: <URL>, iat: <timestamp> }
```

- `typ` MUST be lowercase `dpop+jwt` (not `DPoP+jwt`)
- `htu` MUST exclude query string and fragment — scheme + authority + path only
- Add `nonce` when the server provides one via `DPoP-Nonce` header
- Add `ath` (base64url SHA-256 of access token) when making resource requests

### 3. Pushed Authorization Request (PAR)

POST to the PAR endpoint with all auth parameters in the body.

**The nonce dance:** The first PAR request will typically return HTTP 400 with a `DPoP-Nonce` header. This is expected — extract the nonce, rebuild the DPoP proof with it, and retry. This is not an error condition.

**Required body parameters:**
- `client_id`, `redirect_uri`, `response_type` ("code"), `scope`, `state`
- `code_challenge`, `code_challenge_method` ("S256")
- `client_assertion_type` ("urn:ietf:params:oauth:client-assertion-type:jwt-bearer")
- `client_assertion` (signed JWT — confidential clients only)
- `login_hint` (optional but recommended — the user's DID)

**Headers:** `Content-Type: application/x-www-form-urlencoded`, `DPoP: <proof>`

**Critical:** Always call `.toString()` on `URLSearchParams` when passing as `fetch()` body — some runtimes (notably Cloudflare Workers) don't serialize correctly otherwise.

### 4. User Authorization

Redirect the browser to:
```
{authorization_endpoint}?request_uri={from_PAR}&client_id={client_id}
```

### 5. Callback Verification

The callback returns `code`, `state`, and `iss` parameters. Verify:
- `state` matches the stored value (CSRF protection)
- `iss` matches the expected authorization server (prevents mix-up attacks)

### 6. Token Exchange

POST to token endpoint with `grant_type=authorization_code`, the auth code, `redirect_uri`, `code_verifier`, `client_id`, and client assertion. Include DPoP proof header. Handle nonce retry (same pattern as PAR).

**After receiving tokens, verify `sub`** — the DID in the token response MUST match the DID resolved during identity resolution. This prevents authorization-to-wrong-account attacks.

### 7. Resource Requests

```
Authorization: DPoP <access_token>
DPoP: <proof with ath claim>
```

The `ath` claim is the base64url-encoded SHA-256 hash of the access token. Handle 401 with `DPoP-Nonce` header by retrying with the nonce.

## Token Lifetimes

| Client Type | Access Token | Refresh Token | Overall Session |
|---|---|---|---|
| Public | ≤30 min | ~2 weeks | ~2 weeks |
| Confidential | ≤30 min | ~3 months | ~2 years |

Refresh tokens are **single-use** — each refresh returns a new refresh token. Implement locking to prevent concurrent refresh requests, which would invalidate the session.

## Development & Testing

- **No sandbox exists.** Test against live `bsky.social`.
- **Localhost exception:** Auth servers support `http://localhost` as a `client_id` origin for development.
- **ngrok:** For HTTPS development, tunnel the local server and use the ngrok URL as `PUBLIC_URL` / `client_id`.
- The auth server must be able to reach the client metadata URL — local-only deployments won't work for the PAR step.

## Common Pitfalls

1. **Base64url padding** — The bsky.social server validates JWTs with a Zod schema (`signedJwtSchema`) that only allows base64url chars (`A-Za-z0-9-_`) and dots. If the base64url encoder adds `=` padding, the JWT silently fails Zod validation, the credential union falls through to the `none` type, and the server returns a misleading `"required a client_assertion"` error. **Always use unpadded base64url encoding.** For `@oslojs/encoding`, use `encodeBase64urlNoPadding`, not `encodeBase64url`. This applies to JWT headers, payloads, signatures, PKCE code verifiers, and SHA-256 hashes.
2. **Misleading server errors** — The bsky.social server parses client credentials as a Zod discriminated union (`jwtBearer | secretPost | none`). If the `client_assertion` is present but malformed (padding, wrong format), Zod silently falls through to the `none` schema which strips `client_assertion` entirely. The server then reports "required a client_assertion" when the real issue is JWT format validation failure. Debug by checking the JWT string itself, not the request body.
3. **Body serialization** — `URLSearchParams` passed directly as `fetch()` body may not serialize in all runtimes. Always use `.toString()`.
4. **DPoP `htu` includes query params** — strip them. `htu` is scheme + host + path only. The server validates this with a Zod schema that explicitly rejects query strings and fragments.
5. **Client assertion `aud` wrong** — must be the **authorization server identifier** (the issuer URL, e.g. `https://bsky.social`), NOT the endpoint URL. The server validates `aud` against `authorizationServerIdentifier` from its config. This is different from many OAuth implementations that expect the token endpoint URL.
6. **DPoP `typ` casing** — must be lowercase `dpop+jwt`.
7. **Missing `iss` verification** on callback — required to prevent mix-up attacks.
8. **Missing `sub` verification** after token exchange — required to prevent account confusion.
9. **No nonce retry** — the first PAR/token request almost always returns 400 with a nonce. This is normal.
10. **Client metadata unreachable** — if the auth server can't fetch the `client_id` URL, the entire flow fails silently.
11. **Missing COOKIE_SECRET** — session cookies require an HMAC signing key. Without it, post-OAuth session creation fails even if the OAuth flow itself succeeds.

## Additional Resources

### Reference Files

- **`references/client-metadata.md`** — Full client metadata JSON examples (confidential + public), JWKS endpoint setup, client assertion JWT structure, and ES256 signing notes
