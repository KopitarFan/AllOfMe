# Server REST API

Last updated: 2026-06-29

This document is the contract for the All Of Me Cloud Save REST API. The API
exists to hold encrypted restore points for the Flutter app. The current device
remains the source of truth, and the server never decrypts cloud-save payloads
or becomes the canonical owner of app data.

## Base URLs

- Production: `https://api.allofmeapp.com/`
- Local development: `http://127.0.0.1:3000/`

All paths below are relative to the base URL.

Interactive Swagger docs are served at `/docs`. The generated OpenAPI document
is available as JSON at `/docs/json` and YAML at `/docs/yaml`.

## Design Boundaries

- Cloud Save is backup and restore, not live multi-device sync.
- Bearer tokens identify devices. An account is an internal grouping for linked
  devices, not an email/password user account.
- The server stores token hashes, save metadata, and encrypted
  `CloudSavePackage` JSON files.
- The server validates the package envelope, payload size, base64 encoding, and
  payload checksum, but it does not decrypt or inspect member data, notes,
  profile images, or recovery keys.
- Save reads are always account-scoped from the authenticated device.
- Save lists are returned newest-first.
- Each account keeps at most `CLOUD_SAVE_MAX_VERSIONS` saved versions. The
  default is `5`.

## Request Conventions

- Send JSON request bodies with `Content-Type: application/json`.
- Send `Accept: application/json` when the client expects JSON.
- Dates are ISO 8601 strings.
- Authenticated endpoints require:

```http
Authorization: Bearer <token>
```

- Clients may send `X-Request-ID` with `1-128` characters from
  `A-Z`, `a-z`, `0-9`, `.`, `_`, `:`, or `-`. The server echoes the accepted
  request ID in responses. If the header is missing or invalid, the server
  generates a request ID.

## Error Responses

Errors use one JSON shape:

```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Cloud save package is invalid.",
  "errorId": "err_00000000-0000-0000-0000-000000000000",
  "requestId": "req_00000000-0000-0000-0000-000000000000"
}
```

The server also sends `X-Request-ID` and `X-Error-ID` headers. Client-facing
support screens should show `errorId` when present, then `requestId` as a
fallback.

Common statuses:

| Status | Meaning |
| --- | --- |
| `200` | Request succeeded. |
| `201` | Resource created or save stored. |
| `400` | Request JSON, route parameter, or cloud-save envelope is invalid. |
| `401` | Bearer token is missing or invalid, or a link code is expired/reused. |
| `404` | The requested save does not exist in this account. |
| `413` | The decoded cloud-save payload exceeds `CLOUD_SAVE_MAX_PAYLOAD_BYTES`. |
| `429` | A rate limit was exceeded. Check `Retry-After`. |
| `500` | Unexpected server error. The response message is intentionally generic. |

## Endpoint Reference

### `GET /healthz`

Checks whether the API process is up.

Auth: none.

Rate limit: disabled.

Response:

```json
{
  "ok": true
}
```

### `POST /v1/devices/register`

Creates a new internal account and registers the first device. The bearer token
is returned once. Store it in the app's secure token store.

Auth: none.

Request:

```json
{
  "deviceLabel": "Miguel iPhone"
}
```

`deviceLabel` is optional and must be `1-100` trimmed characters when present.

Response `201`:

```json
{
  "accountId": "account-1782264000000-abcd1234",
  "deviceId": "device-1782264000000-abcd1234",
  "deviceLabel": "Miguel iPhone",
  "token": "aom_redacted",
  "tokenType": "Bearer"
}
```

Notes:

- The server stores only a hash of `token`.
- Re-registration creates a new account. Use device link codes to attach a new
  device to an existing account.

### `POST /v1/devices/link-codes`

Creates a short-lived one-time code that another device can redeem into a token
for the same account.

Auth: bearer token required.

Request:

```json
{}
```

Response `201`:

```json
{
  "code": "AOM-12345-ABCDE",
  "expiresAt": "2026-06-24T12:10:00.000Z"
}
```

Notes:

- The default code lifetime is `DEVICE_LINK_CODE_TTL_MS`, currently
  `600000` ms.
- Codes are stored hashed, are single-use, and cannot be listed back from the
  API.

### `POST /v1/devices/link`

Redeems a valid link code and returns a bearer token for a new device in the
same account.

Auth: none. The link code is the short-lived credential.

Request:

```json
{
  "code": "AOM-12345-ABCDE",
  "deviceLabel": "Miguel iPad"
}
```

`code` is required. The server accepts lowercase input and ignores spaces or
hyphens during normalization. `deviceLabel` is optional and must be `1-100`
trimmed characters when present.

Response `201`:

```json
{
  "accountId": "account-1782264000000-abcd1234",
  "deviceId": "device-1782264600000-efgh5678",
  "deviceLabel": "Miguel iPad",
  "token": "aom_redacted",
  "tokenType": "Bearer"
}
```

### `POST /v1/saves`

Stores one encrypted cloud-save package for the authenticated account.

Auth: bearer token required.

Request: a `CloudSavePackage`.

Response `201`: the package metadata.

```json
{
  "saveId": "cloud-save-1782264000000000",
  "createdAt": "2026-06-23T18:40:00.000Z",
  "appName": "All Of Me",
  "appVersion": "1.0.0+10",
  "snapshotSchemaVersion": 3,
  "deviceLabel": "Miguel iPhone",
  "payloadByteCount": 123456,
  "payloadChecksum": "fnv1a32:1234abcd"
}
```

Validation:

- The JSON object is strict. Unknown fields are rejected.
- `formatVersion` must be `1`.
- `payload.encoding` must be `base64`.
- `payload.compression` must be `none`.
- `payload.encryption.algorithm` must be `xchacha20-poly1305`.
- `payload.encryption.keyDerivationAlgorithm` must be
  `pbkdf2-hmac-sha256`.
- `payload.data`, `nonceBase64`, `saltBase64`, and `macBase64` must be
  canonical base64 with standard `+` and `/` characters and padding.
- Decoded `payload.data` length must match `metadata.payloadByteCount`.
- Decoded `payload.data` must be at or below
  `CLOUD_SAVE_MAX_PAYLOAD_BYTES`.
- `metadata.payloadChecksum` must match the server's FNV-1a checksum over the
  decoded encrypted payload bytes.
- `nonceBase64` must decode to `24` bytes.
- `saltBase64` must decode to `16` bytes.
- `macBase64` must decode to `16` bytes.

Storage behavior:

- `saveId` is unique per account. Uploading the same `saveId` again replaces
  that account's previous copy.
- Retention is enforced after each successful upload.
- The stored package remains encrypted and opaque to the server.

### `GET /v1/saves`

Lists saved-version metadata for the authenticated account.

Auth: bearer token required.

Response `200`:

```json
[
  {
    "saveId": "cloud-save-1782264000000000",
    "createdAt": "2026-06-23T18:40:00.000Z",
    "appName": "All Of Me",
    "appVersion": "1.0.0+10",
    "snapshotSchemaVersion": 3,
    "deviceLabel": "Miguel iPhone",
    "payloadByteCount": 123456,
    "payloadChecksum": "fnv1a32:1234abcd"
  }
]
```

The array is empty when the account has no saves. Ordering is newest-first by
`createdAt`, then by server storage time, then by `saveId`.

### `GET /v1/saves/latest`

Downloads the newest saved package for the authenticated account.

Auth: bearer token required.

Response `200`: a `CloudSavePackage`.

Response `404`: no save exists for this account.

### `GET /v1/saves/:saveId`

Downloads one saved package by ID for the authenticated account.

Auth: bearer token required.

Response `200`: a `CloudSavePackage`.

Response `400`: `saveId` has invalid characters or length.

Response `404`: the save does not exist in this account.

Valid save IDs are `1-128` characters, start with an alphanumeric character,
and may contain alphanumeric characters plus `.`, `_`, `:`, or `-`.

## CloudSavePackage Schema

```json
{
  "formatVersion": 1,
  "metadata": {
    "saveId": "cloud-save-1782264000000000",
    "createdAt": "2026-06-23T18:40:00.000Z",
    "appName": "All Of Me",
    "appVersion": "1.0.0+10",
    "snapshotSchemaVersion": 3,
    "deviceLabel": "Miguel iPhone",
    "payloadByteCount": 123456,
    "payloadChecksum": "fnv1a32:1234abcd"
  },
  "payload": {
    "encoding": "base64",
    "compression": "none",
    "encryption": {
      "algorithm": "xchacha20-poly1305",
      "keyDerivationAlgorithm": "pbkdf2-hmac-sha256",
      "keyDerivationIterations": 120000,
      "keyLengthBits": 256,
      "keyId": "passphrase-recovery-key-v1",
      "nonceBase64": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "saltBase64": "AAAAAAAAAAAAAAAAAAAAAA==",
      "macBase64": "AAAAAAAAAAAAAAAAAAAAAA=="
    },
    "data": "BASE64_ENCRYPTED_PAYLOAD"
  }
}
```

Field constraints:

| Field | Constraint |
| --- | --- |
| `formatVersion` | Literal `1`. |
| `metadata.saveId` | Valid save ID, `1-128` characters. |
| `metadata.createdAt` | Parseable date string. |
| `metadata.appName` | `1-100` trimmed characters. |
| `metadata.appVersion` | Optional, `1-50` trimmed characters. |
| `metadata.snapshotSchemaVersion` | Positive integer. |
| `metadata.deviceLabel` | Optional, `1-100` trimmed characters. |
| `metadata.payloadByteCount` | Positive integer. |
| `metadata.payloadChecksum` | `fnv1a32:` followed by eight lowercase hex digits. |
| `payload.encoding` | Literal `base64`. |
| `payload.compression` | Literal `none`. |
| `payload.encryption.algorithm` | Literal `xchacha20-poly1305`. |
| `payload.encryption.keyDerivationAlgorithm` | Literal `pbkdf2-hmac-sha256`. |
| `payload.encryption.keyDerivationIterations` | Positive integer. |
| `payload.encryption.keyLengthBits` | Positive integer. |
| `payload.encryption.keyId` | `1-128` trimmed characters. |
| `payload.encryption.nonceBase64` | Canonical base64 string that decodes to `24` bytes. |
| `payload.encryption.saltBase64` | Canonical base64 string that decodes to `16` bytes. |
| `payload.encryption.macBase64` | Canonical base64 string that decodes to `16` bytes. |
| `payload.data` | Canonical base64 string. |

## Client Flows

### First Device

1. `POST /v1/devices/register`
2. Store the returned bearer token securely on device.
3. `POST /v1/saves` whenever the user chooses to make a cloud restore point.

### Add Another Device

1. Existing device calls `POST /v1/devices/link-codes`.
2. User enters the code on the new device.
3. New device calls `POST /v1/devices/link`.
4. New device stores the returned bearer token securely.
5. New device can list or download account-scoped saves.

### Restore

1. Client calls `GET /v1/saves` or `GET /v1/saves/latest`.
2. Client downloads a package with `GET /v1/saves/latest` or
   `GET /v1/saves/:saveId`.
3. Client validates checksum, decrypts locally, and asks the user before
   replacing local data.

The restore flow should preserve the product model: cloud copies are manual
restore points, and the local device remains the source of truth.

## Rate Limits

Defaults for the single-container production service:

| Scope | Default |
| --- | --- |
| Global `/v1` requests per client IP | `300` per `60000` ms |
| Device registration per client IP | `5` per `900000` ms |
| Device link-code redemption per client IP | `5` per `900000` ms |
| Save upload per bearer token | `30` per `60000` ms |

`GET /healthz` is not rate limited. Production runs behind Caddy with
`TRUST_PROXY=true`, so Docker must keep the API bound to `127.0.0.1:3000`
rather than exposing port `3000` publicly.

Link-code creation uses the global limit because it already requires a valid
bearer token.

The rate-limit store is in memory and matches the current one-container
deployment. Use a shared store such as Redis before running multiple API
containers.

## Persistence

The default store is `CLOUD_SAVE_STORE=local`.

- Metadata and auth records live in SQLite at
  `CLOUD_SAVE_DATA_DIR/cloud-saves.sqlite`.
- Encrypted package JSON files live under
  `CLOUD_SAVE_DATA_DIR/packages/<accountId>/<saveId>.json`.
- Package files are written to a temporary file and then atomically renamed.
- Admin commands report metadata only and never decrypt package contents.

Tests can use `CLOUD_SAVE_STORE=memory` or inject explicit stores.

## Related Docs

- [Server README](../server/README.md)
- [Production runbook](server-production-runbook.md)
- [Local-first architecture](local-first-architecture.md)
- [Observability options](observability-options.md)
