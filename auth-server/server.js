import crypto from "node:crypto";
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const PORT = Number(process.env.PORT || 3000);
const DATA_PATH = process.env.DATA_PATH || join(__dirname, "data", "auth.json");
const APP_SCHEME = process.env.APP_SCHEME || "brewscan";
const PUBLIC_BASE_URL = (process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`).replace(/\/$/, "");
const FROM_EMAIL = process.env.FROM_EMAIL || "BrewScan <onboarding@resend.dev>";
const RESEND_API_KEY = process.env.RESEND_API_KEY || "";
const TOKEN_SECRET = process.env.TOKEN_SECRET || crypto.randomBytes(32).toString("hex");
const CODE_TTL_MS = 10 * 60 * 1000;
const SESSION_TTL_MS = 180 * 24 * 60 * 60 * 1000;

async function readStore() {
  try {
    return JSON.parse(await readFile(DATA_PATH, "utf8"));
  } catch {
    return { users: {}, loginAttempts: {}, sessions: {} };
  }
}

async function writeStore(store) {
  await mkdir(dirname(DATA_PATH), { recursive: true });
  await writeFile(DATA_PATH, JSON.stringify(store, null, 2));
}

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
  });
  res.end(body);
}

function html(res, status, body) {
  res.writeHead(status, { "Content-Type": "text/html; charset=utf-8" });
  res.end(body);
}

function redirect(res, location) {
  res.writeHead(302, { Location: location });
  res.end();
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function hash(value) {
  return crypto.createHmac("sha256", TOKEN_SECRET).update(value).digest("hex");
}

function randomCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, "0");
}

function randomToken() {
  return crypto.randomBytes(32).toString("base64url");
}

function publicUser(user) {
  return {
    id: user.id,
    email: user.email,
    name: user.name || "",
    createdAt: user.createdAt
  };
}

async function readBody(req) {
  let raw = "";
  for await (const chunk of req) raw += chunk;
  return raw ? JSON.parse(raw) : {};
}

async function sendLoginEmail(email, code, magicUrl) {
  if (!RESEND_API_KEY) {
    console.log(`[auth] Dev login for ${email}: ${code} ${magicUrl}`);
    return { sent: false, provider: "dev" };
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      from: FROM_EMAIL,
      to: email,
      subject: "Your BrewScan login code",
      html: `
        <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#1a0f0a;line-height:1.5">
          <h1 style="margin:0 0 12px">Sign in to BrewScan</h1>
          <p>Your login code is:</p>
          <div style="font-size:32px;font-weight:800;letter-spacing:6px;margin:20px 0;color:#c8860a">${code}</div>
          <p>Or tap this magic link:</p>
          <p><a href="${magicUrl}" style="color:#c8860a;font-weight:700">Open BrewScan</a></p>
          <p style="color:#7b6f65;font-size:13px">This link and code expire in 10 minutes.</p>
        </div>
      `
    })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Resend failed: ${response.status} ${text}`);
  }

  return { sent: true, provider: "resend" };
}

async function createSession(store, email) {
  const token = randomToken();
  const now = Date.now();
  const session = {
    tokenHash: hash(token),
    email,
    createdAt: new Date(now).toISOString(),
    expiresAt: new Date(now + SESSION_TTL_MS).toISOString()
  };
  store.sessions[session.tokenHash] = session;
  return { token, session };
}

async function handleRequestLogin(req, res) {
  const { email: rawEmail, name = "" } = await readBody(req);
  const email = normalizeEmail(rawEmail);
  if (!isValidEmail(email)) return json(res, 400, { error: "Enter a valid email address." });

  const store = await readStore();
  const now = Date.now();
  const code = randomCode();
  const magicToken = randomToken();
  const expiresAt = new Date(now + CODE_TTL_MS).toISOString();

  store.users[email] ||= {
    id: crypto.randomUUID(),
    email,
    name: String(name || "").trim(),
    createdAt: new Date(now).toISOString()
  };
  if (name && !store.users[email].name) store.users[email].name = String(name).trim();

  store.loginAttempts[email] = {
    email,
    codeHash: hash(code),
    magicTokenHash: hash(magicToken),
    expiresAt,
    attempts: 0,
    createdAt: new Date(now).toISOString()
  };

  const magicUrl = `${PUBLIC_BASE_URL}/auth/magic?token=${encodeURIComponent(magicToken)}`;
  const delivery = await sendLoginEmail(email, code, magicUrl);
  await writeStore(store);

  json(res, 200, {
    ok: true,
    email,
    expiresAt,
    emailSent: delivery.sent,
    devCode: RESEND_API_KEY ? undefined : code,
    devMagicLink: RESEND_API_KEY ? undefined : magicUrl
  });
}

async function completeLoginWithAttempt(res, store, attempt) {
  delete store.loginAttempts[attempt.email];
  const { token } = await createSession(store, attempt.email);
  await writeStore(store);
  json(res, 200, { ok: true, token, user: publicUser(store.users[attempt.email]) });
}

async function handleVerifyCode(req, res) {
  const { email: rawEmail, code: rawCode } = await readBody(req);
  const email = normalizeEmail(rawEmail);
  const code = String(rawCode || "").replace(/\D/g, "");
  const store = await readStore();
  const attempt = store.loginAttempts[email];

  if (!attempt || Date.parse(attempt.expiresAt) < Date.now()) {
    return json(res, 400, { error: "That code expired. Send a new one." });
  }
  if (attempt.attempts >= 5) return json(res, 429, { error: "Too many attempts. Send a new code." });
  if (hash(code) !== attempt.codeHash) {
    attempt.attempts += 1;
    await writeStore(store);
    return json(res, 400, { error: "That code does not match." });
  }

  await completeLoginWithAttempt(res, store, attempt);
}

async function handleVerifyMagic(req, res) {
  const { token = "" } = await readBody(req);
  const tokenHash = hash(String(token));
  const store = await readStore();
  const attempt = Object.values(store.loginAttempts).find((item) => item.magicTokenHash === tokenHash);

  if (!attempt || Date.parse(attempt.expiresAt) < Date.now()) {
    return json(res, 400, { error: "That magic link expired. Send a new one." });
  }

  await completeLoginWithAttempt(res, store, attempt);
}

async function handleMe(req, res) {
  const auth = req.headers.authorization || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  const store = await readStore();
  const session = store.sessions[hash(token)];

  if (!session || Date.parse(session.expiresAt) < Date.now()) {
    return json(res, 401, { error: "Not signed in." });
  }

  json(res, 200, { ok: true, user: publicUser(store.users[session.email]) });
}

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url || "/", PUBLIC_BASE_URL);
    if (req.method === "OPTIONS") return json(res, 204, {});
    if (req.method === "GET" && url.pathname === "/health") return json(res, 200, { ok: true });
    if (req.method === "POST" && url.pathname === "/auth/request") return handleRequestLogin(req, res);
    if (req.method === "POST" && url.pathname === "/auth/verify-code") return handleVerifyCode(req, res);
    if (req.method === "POST" && url.pathname === "/auth/verify-magic") return handleVerifyMagic(req, res);
    if (req.method === "GET" && url.pathname === "/auth/me") return handleMe(req, res);
    if (req.method === "GET" && url.pathname === "/auth/magic") {
      const token = url.searchParams.get("token") || "";
      if (token) return redirect(res, `${APP_SCHEME}://auth?token=${encodeURIComponent(token)}`);
      return html(res, 400, "<h1>Missing login token</h1>");
    }
    html(res, 404, "<h1>BrewScan Auth</h1><p>Not found.</p>");
  } catch (error) {
    console.error(error);
    json(res, 500, { error: "Something went wrong. Try again." });
  }
});

server.listen(PORT, () => {
  console.log(`BrewScan auth listening on ${PORT}`);
});
