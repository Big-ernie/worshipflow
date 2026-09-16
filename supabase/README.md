# WorshipFlow Supabase Backend

Production project ID: `fyvtpsneapgwgemugqfd`

Client-safe URL: `https://fyvtpsneapgwgemugqfd.supabase.co`

The production database currently includes:

- profiles
- teams
- team_members
- pad_libraries
- pad_samples
- crowd_libraries
- crowd_samples
- fx_libraries
- fx_samples
- presets
- setlists
- setlist_items
- live_sessions
- live_session_members

Private Storage buckets:

- `pad-audio`
- `crowd-audio`
- `fx-audio`

Realtime is enabled for the live-session foundation used by future WorshipFlow Live / MD Sync.

## Security

Row Level Security is enabled on exposed application tables. Audio buckets are private. Client applications must use the publishable key only. Never commit a Supabase secret key or service-role key.

## Local-first rule

Supabase is the cloud source for account, metadata, collaboration and synchronization. Performance audio should be preloaded to the device and persisted with IndexedDB so an internet interruption cannot stop a service.

## Audio metadata

Pad samples support musical key, major/minor mode, per-sample gain, loop start/end, duration, MIME type and Storage path.

Crowd samples support layer name, minimum and maximum intensity thresholds, gain, loop points and Storage path.

FX samples support slots such as swell, shimmer, impact and sub drop plus custom slots.
