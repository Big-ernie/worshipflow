# CRM Hub backend sources

This directory records the production backend changes used by Big Ernie CRM Hub.

Supabase project: `anedlarzwpestjratbsj`

## WhatsApp commerce layer

- `migrations/20261006_whatsapp_commerce.sql` adds structured customer requests, request items, guided intake sessions, WhatsApp catalog flags, inventory fields, tenant RLS and indexes.
- `functions/whatsapp-webhook/index.ts` is the inbound Meta webhook. It verifies Meta signatures, stores messages and runs the deterministic Intent Router, Sales Capture, Booking and Human Handoff flows.
- `functions/whatsapp-send/index.ts` is the authenticated staff reply endpoint. It enforces workspace/module access and the normal 24-hour free-form WhatsApp reply window.

Never place Meta tokens, app secrets or Supabase service-role keys in this repository.
