# AGENTS.md

These instructions apply to coding agents working inside the CRM Hub directory.

# CRM Hub Coding Guidelines

Derived from the Karpathy-inspired coding discipline in https://github.com/multica-ai/andrej-karpathy-skills and adapted for this project.

## Core behavior

1. Think before coding
- State important assumptions before making non-trivial changes.
- If the request has materially different interpretations, surface them instead of silently choosing one.
- Prefer evidence from the existing code, schema, logs, and tests over guesses.
- If a requested change would weaken tenant isolation, credential safety, or data integrity, stop and explain the risk.

2. Simplicity first
- Implement the smallest complete solution that satisfies the request.
- Do not add speculative frameworks, abstractions, configuration layers, or features.
- Prefer existing project patterns over introducing new architecture.
- If a change can be significantly simpler without losing correctness, simplify it.

3. Surgical changes
- Touch only files and lines needed for the requested outcome.
- Do not reformat, rename, reorganize, or refactor unrelated code.
- Preserve existing behavior unless the task explicitly changes it.
- Remove only dead code created by your own change.

4. Goal-driven execution
- For non-trivial work, define a short plan with explicit verification checks.
- Reproduce bugs before fixing them when practical.
- Verify success with tests, database checks, build checks, logs, or live endpoint checks as appropriate.
- Do not claim success until the relevant verification passes.

## CRM Hub project constraints

- This is a multi-tenant SaaS. Never bypass organization isolation for convenience.
- A platform owner must not gain blanket access to customer CRM records.
- Customer record access requires workspace membership or an explicit, time-limited support grant.
- Preserve Supabase RLS and permission checks. Any new table containing tenant data must include tenant-aware access control.
- Never expose Supabase service-role keys, Meta access tokens, App Secrets, Vault secrets, or other server credentials in browser code, Git history, logs, or responses.
- Sensitive operations should run server-side through authenticated Edge Functions or tightly scoped database routines.
- Raw customer data must not be pooled across tenants for AI training.
- Cross-tenant raw-data use must remain disabled.
- WhatsApp events must resolve to the correct organization before creating contacts, conversations, messages, or appointments.
- Keep webhook processing idempotent where providers may retry delivery.
- Appointment changes must respect booking conflicts and configured availability.
- Quote numbering must remain concurrency-safe.
- Before schema changes, inspect the current schema and policies. Use migrations rather than ad-hoc destructive edits.
- Do not fabricate external integration success. Meta, payment, email, and other third-party integrations are only considered working after a real provider response verifies them.
- Avoid destructive production changes unless explicitly required and verified safe.
- Keep the Vercel frontend and Supabase backend contracts compatible.
- Prefer minimal production-safe fixes over broad rewrites.

## Definition of done

A change is complete only when:
- the requested behavior exists,
- relevant syntax/build/database checks pass,
- tenant and credential boundaries remain intact,
- no unrelated behavior was changed,
- temporary QA data is removed or rolled back,
- and the live deployment is checked when the change affects production.

