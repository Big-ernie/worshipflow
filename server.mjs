import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.join(__dirname, 'public');
const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');
const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || '127.0.0.1';

fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify({ users: [], sessions: [], presets: [], setlists: [] }, null, 2));
}

const mime = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon', '.webmanifest': 'application/manifest+json'
};

function readDB() { return JSON.parse(fs.readFileSync(DB_FILE, 'utf8')); }
function writeDB(db) { fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2)); }
function json(res, status, body, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...headers });
  res.end(JSON.stringify(body));
}
function parseCookies(req) {
  const out = {};
  for (const item of (req.headers.cookie || '').split(';')) {
    const i = item.indexOf('='); if (i < 0) continue;
    out[item.slice(0, i).trim()] = decodeURIComponent(item.slice(i + 1));
  }
  return out;
}
function body(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', chunk => { raw += chunk; if (raw.length > 1_000_000) req.destroy(); });
    req.on('end', () => { try { resolve(raw ? JSON.parse(raw) : {}); } catch { reject(new Error('Invalid JSON')); } });
    req.on('error', reject);
  });
}
function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}
function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(':');
  if (!salt || !hash) return false;
  const candidate = crypto.scryptSync(password, salt, 64);
  const expected = Buffer.from(hash, 'hex');
  return candidate.length === expected.length && crypto.timingSafeEqual(candidate, expected);
}
function currentUser(req, db) {
  const token = parseCookies(req).wf_session;
  if (!token) return null;
  const session = db.sessions.find(s => s.token === token && s.expiresAt > Date.now());
  return session ? db.users.find(u => u.id === session.userId) || null : null;
}
function publicUser(u) { return u ? { id: u.id, email: u.email, name: u.name, plan: u.plan || 'free', createdAt: u.createdAt } : null; }
function newId(prefix) { return `${prefix}_${crypto.randomBytes(10).toString('hex')}`; }
function sessionCookie(token, maxAge = 60 * 60 * 24 * 30) {
  return `wf_session=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}`;
}
function requireAuth(req, res, db) {
  const user = currentUser(req, db);
  if (!user) { json(res, 401, { error: 'Sign in required' }); return null; }
  return user;
}

async function handleApi(req, res, url) {
  const db = readDB();
  if (url.pathname === '/api/health') return json(res, 200, { ok: true, service: 'WorshipFlow', time: new Date().toISOString() });
  if (url.pathname === '/api/me' && req.method === 'GET') return json(res, 200, { user: publicUser(currentUser(req, db)) });

  if (url.pathname === '/api/register' && req.method === 'POST') {
    const data = await body(req).catch(() => null);
    if (!data) return json(res, 400, { error: 'Invalid request' });
    const name = String(data.name || '').trim().slice(0, 80);
    const email = String(data.email || '').trim().toLowerCase().slice(0, 180);
    const password = String(data.password || '');
    if (!name || !email.includes('@') || password.length < 8) return json(res, 400, { error: 'Use a name, valid email and password of at least 8 characters' });
    if (db.users.some(u => u.email === email)) return json(res, 409, { error: 'An account with this email already exists' });
    const user = { id: newId('usr'), name, email, passwordHash: hashPassword(password), plan: 'free', createdAt: Date.now() };
    const token = newId('sess');
    db.users.push(user); db.sessions.push({ token, userId: user.id, expiresAt: Date.now() + 30 * 86400_000 }); writeDB(db);
    return json(res, 201, { user: publicUser(user) }, { 'Set-Cookie': sessionCookie(token) });
  }

  if (url.pathname === '/api/login' && req.method === 'POST') {
    const data = await body(req).catch(() => null);
    if (!data) return json(res, 400, { error: 'Invalid request' });
    const email = String(data.email || '').trim().toLowerCase(); const password = String(data.password || '');
    const user = db.users.find(u => u.email === email);
    if (!user || !verifyPassword(password, user.passwordHash)) return json(res, 401, { error: 'Incorrect email or password' });
    const token = newId('sess'); db.sessions.push({ token, userId: user.id, expiresAt: Date.now() + 30 * 86400_000 }); writeDB(db);
    return json(res, 200, { user: publicUser(user) }, { 'Set-Cookie': sessionCookie(token) });
  }

  if (url.pathname === '/api/logout' && req.method === 'POST') {
    const token = parseCookies(req).wf_session; db.sessions = db.sessions.filter(s => s.token !== token); writeDB(db);
    return json(res, 200, { ok: true }, { 'Set-Cookie': sessionCookie('', 0) });
  }

  if (url.pathname === '/api/presets' && req.method === 'GET') {
    const user = requireAuth(req, res, db); if (!user) return;
    return json(res, 200, { presets: db.presets.filter(p => p.userId === user.id).sort((a,b) => b.updatedAt - a.updatedAt) });
  }
  if (url.pathname === '/api/presets' && req.method === 'POST') {
    const user = requireAuth(req, res, db); if (!user) return;
    const data = await body(req).catch(() => null); if (!data) return json(res, 400, { error: 'Invalid request' });
    const preset = { id: newId('pre'), userId: user.id, name: String(data.name || 'Untitled preset').trim().slice(0,80), state: data.state || {}, updatedAt: Date.now(), createdAt: Date.now() };
    db.presets.push(preset); writeDB(db); return json(res, 201, { preset });
  }
  if (url.pathname.startsWith('/api/presets/') && req.method === 'DELETE') {
    const user = requireAuth(req, res, db); if (!user) return;
    const id = url.pathname.split('/').pop(); const before = db.presets.length; db.presets = db.presets.filter(p => !(p.id === id && p.userId === user.id)); writeDB(db);
    return json(res, before === db.presets.length ? 404 : 200, before === db.presets.length ? { error: 'Preset not found' } : { ok: true });
  }

  if (url.pathname === '/api/setlists' && req.method === 'GET') {
    const user = requireAuth(req, res, db); if (!user) return;
    return json(res, 200, { setlists: db.setlists.filter(s => s.userId === user.id).sort((a,b) => b.updatedAt - a.updatedAt) });
  }
  if (url.pathname === '/api/setlists' && req.method === 'POST') {
    const user = requireAuth(req, res, db); if (!user) return;
    const data = await body(req).catch(() => null); if (!data) return json(res, 400, { error: 'Invalid request' });
    const setlist = { id: newId('set'), userId: user.id, name: String(data.name || 'Sunday Set').trim().slice(0,80), items: Array.isArray(data.items) ? data.items.slice(0,50) : [], updatedAt: Date.now(), createdAt: Date.now() };
    db.setlists.push(setlist); writeDB(db); return json(res, 201, { setlist });
  }
  if (url.pathname.startsWith('/api/setlists/') && req.method === 'PUT') {
    const user = requireAuth(req, res, db); if (!user) return;
    const id = url.pathname.split('/').pop(); const data = await body(req).catch(() => null); const setlist = db.setlists.find(s => s.id === id && s.userId === user.id);
    if (!setlist) return json(res, 404, { error: 'Setlist not found' });
    if (data?.name) setlist.name = String(data.name).trim().slice(0,80); if (Array.isArray(data?.items)) setlist.items = data.items.slice(0,50); setlist.updatedAt = Date.now(); writeDB(db);
    return json(res, 200, { setlist });
  }

  json(res, 404, { error: 'Not found' });
}

function serveStatic(req, res, url) {
  let rel = decodeURIComponent(url.pathname);
  if (rel === '/') rel = '/index.html';
  const file = path.normalize(path.join(PUBLIC_DIR, rel));
  if (!file.startsWith(PUBLIC_DIR)) { res.writeHead(403); return res.end('Forbidden'); }
  fs.stat(file, (err, stat) => {
    if (err || !stat.isFile()) {
      const fallback = path.join(PUBLIC_DIR, 'index.html');
      return fs.readFile(fallback, (e, data) => { if (e) { res.writeHead(404); return res.end('Not found'); } res.writeHead(200, { 'Content-Type': mime['.html'] }); res.end(data); });
    }
    const ext = path.extname(file); const headers = { 'Content-Type': mime[ext] || 'application/octet-stream' };
    if (['.js','.css','.svg'].includes(ext)) headers['Cache-Control'] = 'public, max-age=3600';
    res.writeHead(200, headers); fs.createReadStream(file).pipe(res);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  try {
    if (url.pathname.startsWith('/api/')) await handleApi(req, res, url); else serveStatic(req, res, url);
  } catch (err) {
    console.error(err); if (!res.headersSent) json(res, 500, { error: 'Server error' }); else res.end();
  }
});
server.listen(PORT, HOST, () => console.log(`WorshipFlow running at http://${HOST}:${PORT}`));
