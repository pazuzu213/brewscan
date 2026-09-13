# PodSnap AI Auth

Small email-code login API for PodSnap AI.

## Endpoints

- `POST /auth/request` with `{ "email": "...", "name": "..." }`
- `POST /auth/verify-code` with `{ "email": "...", "code": "123456" }`
- `GET /auth/me` with `Authorization: Bearer <session-token>`

## Env

- `RESEND_API_KEY` sends real email. Without it, responses include `devCode`.
- `FROM_EMAIL`, default `PodSnap AI <onboarding@resend.dev>`
- `APP_ICON_URL`, default `https://brewscan.app/podscan-icon.png`
- `PUBLIC_BASE_URL`, production API URL
- `TOKEN_SECRET`, required for stable production session/code hashing
