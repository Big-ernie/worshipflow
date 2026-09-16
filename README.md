# WorshipFlow V2

WorshipFlow is a live worship atmosphere engine for gospel musicians, session players, producers, music directors and churches.

The current build combines a local-first Web Audio performance engine with optional Supabase cloud sync.

## Run it

```bash
npm start
```

Open `http://127.0.0.1:8787`.

## Included in this build

- 12-key major/minor worship pad engine
- Custom sample-based pad libraries
- WAV, AIFF and MP3 import through the browser
- IndexedDB storage for imported audio, so custom pads remain on the device
- Seamless looping using Web Audio BufferSource looping
- Configurable key crossfade from 0.5 to 10 seconds
- Synth fallback when a custom sample is missing
- Supabase email/password authentication
- Private Supabase Storage sync to the `pad-audio` bucket
- Supabase pad library and sample metadata sync
- Adaptive synthesized crowd ambience
- Worship moment presets: Prayer, Soft Worship, Build, Climax, Altar Call and Praise
- Transition FX: swell, impact, shimmer and sub drop
- Click track with BPM control and tap tempo
- Keyboard shortcuts and Web MIDI input
- Local presets and service setlist
- PWA shell and offline static asset caching
- Responsive dark stage interface

## How to add your own pads

1. Start WorshipFlow and scroll to **Pad Library**.
2. Click **New pack**, for example `Warm Worship`.
3. Choose **Major** or **Minor** before uploading that set of samples.
4. Use the Upload button under each key: C, C#, D, D#, E, F, F#, G, G#, A, A# and B.
5. Select the matching audio file for each key.
6. The slot turns green when a custom sample is available.
7. Press **Start audio**, then select a key. WorshipFlow uses your custom file when available and the synthesized fallback when it is not.
8. Adjust **Crossfade** to control how long the previous key fades out while the new key fades in.

Recommended source audio:

- Stereo WAV preferred
- 24-bit
- 44.1 kHz or 48 kHz
- Seamlessly loopable
- Similar perceived loudness across all keys
- No clipping
- Leave a little headroom, for example peaks below roughly -1 dBFS

Imported audio is stored locally in IndexedDB. This means the files do not need to be re-selected every time you reopen the app on the same browser profile.

## Cloud sync

Click **Sign in** to create or access a WorshipFlow account. After signing in, click **Sync cloud** in the Pad Library.

The active pack is uploaded to the private Supabase `pad-audio` bucket. Metadata is stored in `pad_libraries` and `pad_samples`. The browser only contains the Supabase publishable key. Never commit a secret key or service-role key.

Cloud sync is optional. Live performance playback remains local-first.

## Keyboard shortcuts

- Chromatic keys: `A W S E D F T G Y H U J`
- Worship moments: `1` to `6`
- Toggle click: `Space`
- Stop audio: `Esc`

## MIDI

Press MIDI and allow access. MIDI Note On selects the corresponding chromatic key. CC1, the mod wheel, controls intensity.

## Production backend

Supabase project: `WorshipFlow`

Project ref: `fyvtpsneapgwgemugqfd`

Configured services include Postgres, Auth, Storage, Realtime and RLS-protected tables for pad libraries, crowd libraries, FX, teams, presets, setlists and future MD Live sessions.

## Next production priorities

- Cloud restore/download of pad packs onto a new device
- Per-sample loop start/end editor
- Per-sample gain controls
- Real layered crowd sample libraries
- Custom FX sample slots
- MIDI Learn
- Improved setlist editor
- WorshipFlow Live / MD Sync
- Native desktop version if ultra-low latency requirements justify it

## Security

Keep `.env`, service-role keys and all Supabase secret keys out of GitHub. `.env.example` contains only client-safe configuration.
