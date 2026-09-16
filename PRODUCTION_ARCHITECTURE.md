# WorshipFlow Production Architecture

## Client

- Web management surface for accounts, libraries, teams and billing
- Installable PWA first for stage use
- Web Audio API for current playback engine
- IndexedDB for local-first offline audio packs
- Web MIDI for controllers and footswitches
- Native JUCE/C++ stage engine later if browser latency or reliability becomes limiting

## Backend

- Supabase Postgres for metadata
- Supabase Auth for user accounts
- Supabase Storage for pad, crowd and FX audio
- Supabase Realtime for WorshipFlow Live / MD Sync
- Private buckets and Row Level Security

## Current production data model

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

## Audio policy

Every included or marketplace audio asset must have a documented license and permitted commercial usage. WorshipFlow should never scrape copyrighted congregation recordings or music from third-party services.

## Offline model

Users explicitly download or import sound packs to the device. Performance playback reads local assets. Cloud sync must never be required to keep audio running during a service.

## Reliability priorities

1. Preload/decode audio before performance
2. Seamless loop points
3. Smooth key crossfades
4. Local recovery after refresh/crash
5. Panic/stop-all control
6. Asset integrity checks
7. Clear stable/beta release channels
