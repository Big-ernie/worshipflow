# Neon Free migration, Big Ernie CRM Hub

Status (2026-10-13): **development infrastructure provisioned, production remains on Supabase.** This document is for a safe, reversible, no-cost migration.

## Existing source and production

- Source: `crm-hub/index.html` and `crm-hub/backend/` in this repository.
- Live Supabase project: `anedlarzwpestjratbsj` (active), **not** `oeuweerjijaczzsesccr` (paused Pack Hub CRM).
- Live frontend deployment: `big-ernie-crm-hub.vercel.app`.
- PostgreSQL 17; active DB has 30 public tables, 22 public functions, 97 RLS policies and 42 non-internal triggers.
- Browser uses Supabase JS 2 directly for authentication, PostgREST table queries, RPCs, and Edge Function invokes.
- Meta WhatsApp and workspace admin routes depend on Edge Functions and service-role verification.
- Existing users sign in with Supabase Auth. **Passwords and sessions do not automatically migrate to Neon Auth.**

## Provisioned Neon Free development project

- Organization: `Ernest`, Free plan.
- Project: `Big Ernie CRM Hub Dev`, ID `ancient-art-54352309`.
- Region: `aws-eu-central-1` (Frankfurt), PostgreSQL 17.
- Branch: `main`, ID `br-winter-block-b9l0cwr4`.
- Database: `crmhub_dev`.
- Neon Managed Better Auth: enabled on the development branch.
- Neon Data API: provisioned with **no default grants**, to prevent unreviewed table exposure.
- No Supabase records, customers, credentials, Meta tokens or production data have been imported.
- No live frontend, DNS, WhatsApp webhook, production Supabase setting, Vercel environment variable or billing plan has been changed.

## Migration compatibility notes

Official guide: `https://neon.com/docs/auth/migrate/from-supabase`. For the **database and browser Auth API**, `@neondatabase/neon-js` supports `SupabaseAuthAdapter()` and familiar `.from()` calls when Neon Auth and Data API are enabled.

The existing CRM also relies on Supabase-managed schemas (`auth.users` and `auth.uid()`), RLS policies and many server-side SQL functions. All must be securely translated to Neon Auth. Supabase Edge Functions `sb.functions.invoke()` are **not** recreated by switching the DB client: replace or proxy them through authenticated endpoints, port Meta webhooks securely, and verify tenant boundaries.

The current 'Forgot password' flow calls `updateUser({password})` which **is not supported** by Neon Managed Auth's Supabase adapter. Change the UI to Neon Auth's supported password recovery method; do not silently break the reset flow.

## Required migration checkpoints

1. Export a password-protected **private** backup of the active Supabase database and test restoring it in an isolated environment. Never commit backups, passwords, connection strings, customer data, or API keys in this public repository.
2. Inventory all 30 public tables, 22 functions, 97 policies, 42 triggers, foreign keys, extensions, and privileges. Identify every dependency on `auth.users`, `auth.uid()`, storage, realtime and Supabase Edge Functions.
3. Build the schema and authorization model in **Neon development only**. Apply no default anonymous grants, configure tenant-scoped RLS and/or authenticated server-side authorization, test cross-tenant reads/writes with separate identities.
4. Implement a separate staging frontend using `@neondatabase/neon-js` with `SupabaseAuthAdapter()`. Configure trusted callback domains for the staging origin only.
5. Implement profile provisioning, workspace creation/invitations, modules and role-based access, CRM CRUD, quoting, audit log and reporting; then port Meta webhook and staff replies with signature verification and 24-hour reply checks in sandbox only.
6. Reconcile non-secret data and enforce explicit authentication re-enrollment if password login is used. Do not assume Supabase password hashes or existing sessions transfer to Neon.
7. Test signup/login/logout/recovery, all major workflows, tenant isolation, Webhook signature rejection, error handling and backup/restore.
8. Review Free plan quotas, billing and capacity. Obtain user approval before touching the **live** Vercel deployment, DNS, Meta integration or production data.
9. Preserve a working Supabase fallback until post-cutover checks pass.

## Safety rules

- Never commit credentials to this public repository.
- **Do not** replace the current Supabase URL with a Neon URL in the existing production `createClient()` code: that is not a functional migration.
- Until the full auth, policy, database, and webhook tests pass, leave functioning production unchanged.
- The paused Pack Hub CRM project and the active Big Ernie CRM Hub project are distinct and must not be confused.


## Staging schema parity update (2026-10-14)

- The `crm_stage` schema was created on the Neon development database, **not on live CRM**.
- Verified 30 empty CRM tables, 329 column definitions, 71 source non-FK constraints, 79 internal foreign keys, and 117 indexes.
- The one remaining external foreign key, `profiles_id_fkey` from `public.profiles(id)` to Supabase `auth.users(id)`, is **intentionally deferred** pending an identity migration to Neon `neon_auth.user(id)`.
- Every staging table has RLS enabled. There are zero migrated RLS policies, and both anonymous and authenticated roles lack usage privileges on the staging schema. This is a **closed test environment**, not a functioning tenant-secure customer backend.
- Source counts: 2 confirmed password-based users, 2 workspaces, 2 profiles, 18 deals, 8 products/services and 2 subscriptions. **No individual email addresses, account IDs, credentials or customer records were copied.**
- Source and staging schema structures are now suitable for **offline schema review only**. Not yet suitable for client sign-in or customer data imports.

### Mandatory next work

1. Choose the user re-enrollment process for the 2 existing password-based accounts. Neon Auth does not migrate Supabase password hashes.
2. Preserve user identity to profile/workspace relationships securely. Record a private mapping only when authorized. Never migrate records without tested identity associations.
3. Translate workspace and module RLS, helper functions, triggers and Edge Functions into a tested Neon Auth/Data API security design before exposing any table.
4. Create an isolated staging frontend and run negative authorization tests with unrelated test workspaces.
5. Export a private, restorable backup and run a dry-run data import without copying customer credentials or WhatsApp tokens.
6. Keep production Supabase and Meta webhooks untouched until full functionality, billing and rollback verification.


## Private Neon functional preview (2026-10-14)

**Status: staging implementation deployed; browser sign-in by a real test user not yet exercised.**

- Stable Vercel preview URL: https://big-ernie-crm-hub-git-plan-neon-free-crm-migration-big-ernie.vercel.app/neon-preview
- GitHub files `crm-hub/neon-preview.html`, `.css`, and `.js` use Neon JS v0.7.0-beta with `SupabaseAuthAdapter()` and the staging Data API only. Vercel Preview Authentication remains enabled.
- Neon Auth email/password and development Google OAuth are available for a NEW test login, separate from the two existing Supabase password identities. Browser sign-up/sign-in and redirect flows still require human test completion.
- Neon Data API's **sole exposed schema** is `crm_stage`, with CORS set to the stable protected preview hostname. Neon Auth trust list includes that hostname. No live production domain was switched to Neon.
- Preview has login, new workspace creation, company switching, sales pipeline CRUD and customer contacts CRUD. WhatsApp, subscription charging and invites are explicitly disabled, not silently redirected to live systems.
- `crm_stage` has 30 tables, 79 internal FKs, 117 indexes, 13 module metadata rows and 78 role/module defaults. The Supabase-specific `profiles.id -> auth.users` FK remains intentionally deferred.
- Added staging RPCs `preview_bootstrap_profile`, `preview_create_workspace`, `preview_owns_workspace` and `preview_identity`. Function permissions restrict unauthenticated callers; only an owner may see/write their own workspace data in this preview. Other tables remain inaccessible by default.
- Neon-owned `auth` schema grants are not available to the database `authenticated` role. Therefore RLS policies use a tightly scoped owner-owned `preview_identity()` wrapper to evaluate the verified request subject. Direct `auth.uid()` from `authenticated` produced a permission error; this is explicitly tested and addressed.
- SQL role/JWT-claim **simulation** verified: User Alpha created a development test workspace and deal; User Beta had one own workspace, observed zero of Alpha's rows and was blocked on cross-workspace deal INSERT. This is not a substitute for testing with real Neon-issued JWTs through the browser and Data API.
- All demo records use synthetic IDs. No customer data, payments, real contacts, existing user password hashes, or WhatsApp secrets were copied.
- The preview URL is stable across additional commits on this branch. No production deployment has been promoted.

### Still blocked from production switchover

- Real test-user sign-up and session persistence verification, including OAuth.
- Email verification/production SMTP, password recovery and existing-user re-enrollment procedure.
- Full RBAC, 97 production-equivalent RLS policies, triggers, audit and service functions, strong relationship invariants.
- Secure full backup with restoration test, then reconciled real-record import with correct user identity mapping.
- Meta webhook, WhatsApp outbound reply, payment/billing integration and related secrets migration in an isolated sandbox.
- Negative tests with actual signed Neon Auth JWTs, performance smoke, rollback rehearsal and explicit production approval.

Do not merge/promote this branch to production as a completed Supabase replacement. The primary `index.html` remains the Supabase-powered production UI.
