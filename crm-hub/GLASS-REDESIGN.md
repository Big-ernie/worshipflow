# Big Ernie Glass Command Centre, design preview and integration notes

**Date:** 20 November 2026  
**Status:** Preview branch, not production

## Product scope

Two secure applications, one visual design system:

1. **Big Ernie CRM Hub**, source: `Big-ernie/worshipflow/crm-hub`, deployed under Vercel project `big-ernie-crm-hub`. The existing application uses Supabase project `anedlarzwpestjratbsj`.
2. **Big Ernie Studios Studio Command**, live website editor at `https://www.bigerniestudios.com/dashboard/`, deployed from the separate `big-ernie-studios-showcase` Vercel project. The existing admin publishes content through its own `/api/cms` and handles enquiries through `/api/enquiries`.

These applications currently have **separate authentication** and data storage. This patch does not unify authentication or change access controls.

## Files in this branch

- `crm-hub/glass-command.css`: responsive light/dark glass design layer for the existing CRM, applied after original CSS.
- `crm-hub/glass-command.js`: additional light/dark toggle, command search (Cmd/Ctrl + K), and link to Studio Command. It does not replace application navigation or API handlers.
- `crm-hub/index.html`: inserts the two CRM design assets. The inline Supabase CRM application code remains in place.
- `crm-hub/studio-command-glass.css`: matching, non-destructive CSS adapter for the separate Studio Command website editor. **Not installed on the live studio website.**
- `crm-hub/studio-command-preview.html`: standalone interactive visual preview with no backend privileges, no private client data, and explicit local-only draft behavior.

## Shared design language

Warm ivory translucent cards, forest/graphite navigation, muted champagne accents, subtle backdrop blur, soft elevation, flexible card grids, system fonts, expressive serif titles, clearly visible focus rings, responsive layouts, and reduced-motion fallbacks.

## Validation completed

- Vercel feature branch deployment reached **READY**.
- Existing CRM HTML and the two new CRM assets served HTTP 200.
- Studio Command preview HTML and CSS served HTTP 200.
- Interactive browser checks confirmed Studio Command view navigation, local page editor live preview, and light/dark toggle.
- No production site files, data tables, RLS rules, stored customer enquiries, or passwords were changed.

## Not yet validated

- Existing authenticated CRM workflows after logging in, including authorization-sensitive actions, because no credentials were entered.
- Actual studio-editor integration in its own Vercel project.
- Cross-browser and small-device visual-regression testing.
- Real analytics or content publication from the design preview.
- Full accessibility audit.

## Website admin integration procedure

The existing `big-ernie-studios-showcase` deployment contains `dashboard/index.html`, `dashboard/dashboard.css`, `dashboard/dashboard.js`, `dashboard/studio-redesign.css`, `dashboard/studio-redesign.js`, and the CMS functions. The project does not currently expose a Git-linked source repository through the connected GitHub account.

To integrate the companion theme safely:

1. Obtain or reconstruct the canonical source-controlled version of the separate website project, including its serverless API handlers, site pages, assets and package settings. Preserve production configuration and secrets outside version control.
2. Add `studio-command-glass.css` under the existing dashboard asset directory. Include it **after** current dashboard styles in the real Studio Command page.
3. Apply `be-glass-site` to the dashboard's body only, never to public website pages.
4. Add a carefully reviewed theme toggle and CRM switcher that respect existing session logic. Avoid changing `/api/cms` and `/api/enquiries` behavior.
5. Create a **preview** deployment containing the full original website source, compare login, navigation, media, copy editing and publishing, and verify the dashboard is still `noindex`.
6. After user approval and regression checks, release separately from the CRM design.

**Do not** deploy only these CSS files as a replacement for the original website project, because its existing CMS and API backend would be lost.

## Release safety

Do not merge this branch until the logged-in CRM has been regression-tested and the design has been reviewed on desktop, tablet and mobile. A merge to `main` may automatically trigger a Vercel deployment. Keep this PR in draft until explicitly approved.
