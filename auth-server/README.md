# BrewScan Auth

Small email login API for BrewScan.

## Endpoints

- `POST /auth/request` with `{ "email": "...", "name": "..." }`
- `POST /auth/verify-code` with `{ "email": "...", "code": "123456" }`
- `POST /auth/verify-magic` with `{ "token": "..." }`
- `GET /auth/magic?token=...` redirects into `brewscan://auth?token=...`
- `GET /auth/me` with `Authorization: Bearer <session-token>`

## Env

- `RESEND_API_KEY` sends real email. Without it, responses include `devCode` and `devMagicLink`.
- `FROM_EMAIL`, default `BrewScan <onboarding@resend.dev>`
- `PUBLIC_BASE_URL`, production API URL
- `APP_SCHEME`, default `brewscan`
- `TOKEN_SECRET`, required for stable production session/code hashing
