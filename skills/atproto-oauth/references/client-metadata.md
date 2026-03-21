# Client Metadata Reference

No registration process exists. Publish JSON at an HTTPS URL — that URL is the `client_id`. The auth server fetches it dynamically. It must return HTTP 200, `Content-Type: application/json`, with **no redirects**.

## Confidential Client (Server-Side)

```json
{
  "client_id": "https://example.com/oauth/client-metadata.json",
  "client_name": "My App",
  "client_uri": "https://example.com",
  "redirect_uris": ["https://example.com/oauth/callback"],
  "grant_types": ["authorization_code", "refresh_token"],
  "scope": "atproto transition:generic",
  "response_types": ["code"],
  "application_type": "web",
  "token_endpoint_auth_method": "private_key_jwt",
  "token_endpoint_auth_signing_alg": "ES256",
  "dpop_bound_access_tokens": true,
  "jwks_uri": "https://example.com/oauth/jwks.json"
}
```

## Public Client (Browser)

Set `token_endpoint_auth_method: "none"`. No keys needed. Session limited to ~2 weeks.

## JWKS Endpoint

Serve public key(s) in JWK format with `kid`, `use: "sig"`, `alg: "ES256"`.

## ES256 Signing Notes

- Use ECDSA with P-256 curve and SHA-256 hash
- Web Crypto may return DER-encoded signatures — convert to raw r||s format (64 bytes for P-256) for JWS
- For client keys: private key as PKCS8, public key as SPKI, both base64-encoded
- For DPoP keys: generate ephemeral per session, serialize as JWK for storage

## Client Assertion (Confidential Clients)

JWT signed with the client's private key:

```
Header: { typ: "JWT", alg: "ES256", kid: <key-id> }
Payload: {
  iss: <client_id>,
  sub: <client_id>,
  aud: <endpoint URL being called>,
  jti: <uuid>,
  iat: <timestamp>,
  exp: <timestamp + 60s>
}
```

The `aud` must be the **endpoint URL** being called — PAR endpoint for PAR requests, token endpoint for token exchange. Not the issuer URL.
