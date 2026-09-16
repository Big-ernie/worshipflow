const base = process.env.WORSHIPFLOW_URL || 'http://127.0.0.1:8787';
const health = await fetch(`${base}/api/health`).then(r => r.json());
if (!health.ok) throw new Error('Health check failed');
const html = await fetch(base).then(r => r.text());
for (const token of ['WorshipFlow','WORSHIP MOMENTS','Start audio']) {
  if (!html.includes(token)) throw new Error(`Missing UI token: ${token}`);
}
console.log('Smoke test passed:', health.service);
