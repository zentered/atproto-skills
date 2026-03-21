# DID Document Examples

## did:plc Document

Resolved via `https://plc.directory/{did}`:

```json
{
  "@context": ["https://www.w3.org/ns/did/v1", "https://w3id.org/security/multikey/v1", "https://w3id.org/security/suites/secp256k1-2019/v1"],
  "id": "did:plc:abc123",
  "alsoKnownAs": ["at://alice.bsky.social"],
  "verificationMethod": [
    {
      "id": "did:plc:abc123#atproto",
      "type": "Multikey",
      "controller": "did:plc:abc123",
      "publicKeyMultibase": "zQ3sh..."
    }
  ],
  "service": [
    {
      "id": "#atproto_pds",
      "type": "AtprotoPersonalDataServer",
      "serviceEndpoint": "https://morel.us-east.host.bsky.network"
    }
  ]
}
```

### Key Fields

- `alsoKnownAs` — contains the `at://` URI with the current handle
- `verificationMethod` — signing keys for the account (used to verify repo commits)
- `service[#atproto_pds]` — the PDS endpoint; this is where authenticated XRPC requests go

## did:web Document

Resolved via `https://{domain}/.well-known/did.json`:

```json
{
  "@context": ["https://www.w3.org/ns/did/v1"],
  "id": "did:web:example.com",
  "alsoKnownAs": ["at://example.com"],
  "verificationMethod": [
    {
      "id": "did:web:example.com#atproto",
      "type": "Multikey",
      "controller": "did:web:example.com",
      "publicKeyMultibase": "zQ3sh..."
    }
  ],
  "service": [
    {
      "id": "#atproto_pds",
      "type": "AtprotoPersonalDataServer",
      "serviceEndpoint": "https://pds.example.com"
    }
  ]
}
```

`did:web` is typically used by self-hosted PDS operators who control their own domain.

## PLC Directory Operations

The PLC directory at `plc.directory` supports:

- `GET /{did}` — current DID document
- `GET /{did}/log` — full operation log (history of all changes)
- `GET /{did}/log/audit` — audit log
- `GET /{did}/log/last` — most recent operation

## Extracting the PDS Endpoint

From a DID document, find the service with `id: "#atproto_pds"`:

```
did_doc.service.find(s => s.id === "#atproto_pds").serviceEndpoint
```

This URL is the base for all authenticated XRPC calls for that user.
