# WorshipFlow MVP

WorshipFlow is a live worship atmosphere engine for gospel musicians, session players, producers, music directors and churches.

This MVP is deliberately dependency-free. It runs with Node.js only and generates its pad, crowd ambience, transitions and click inside the browser using the Web Audio API.

## Run it

```bash
npm start
```

Open `http://127.0.0.1:8787`.

## Included in this build

- 12-key major/minor drone pad engine with smooth key crossfades
- Adaptive pad tone based on live intensity
- Synthesized live-room/crowd ambience with adaptive responses
- Worship moment presets: Prayer, Soft Worship, Build, Climax, Altar Call, Praise
- Transition FX: swell, impact, shimmer and sub drop
- Click track with BPM control and tap tempo
- Keyboard shortcuts and Web MIDI input
- Local presets and service setlist
- Built-in account registration/login and cloud-style sync using the local server database
- Installable PWA shell and offline static asset caching
- Responsive dark stage interface
- Zero external packages or CDNs

## Production backend

The Supabase production project is configured separately. Use `.env.example` as the safe client configuration template. Never commit service-role or secret keys.

## Keyboard shortcuts

- Chromatic keys: `A W S E D F T G Y H U J`
- Worship moments: `1` to `6`
- Toggle click: `Space`
- Stop audio: `Esc`

## MIDI

Press MIDI and allow access. MIDI Note On selects the corresponding chromatic key. CC1 (mod wheel) controls intensity.

## Important production notes

This repository is a functional MVP moving toward the production SaaS. The next implementation priorities are custom sample-based pad libraries, IndexedDB offline audio, crowd sample layering, Supabase authentication/storage sync, MIDI Learn, setlist upgrades, and WorshipFlow Live/MD Sync.

## Data

Local demo account data lives in `data/db.json`. Do not commit real user credentials or production data.
