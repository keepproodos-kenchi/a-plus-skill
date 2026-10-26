# Layer 3 — Web Client Playbook

**Status:** Reference v2.0. Applies when `roles` includes `web`: browser applications of any
rendering model (SPA such as React + Vite, SSR or hybrid such as Next.js, Nuxt, SvelteKit,
Remix, Astro islands) and installable PWAs. Binds to Layer 1 and 2 controls. Rows without an
"Applies when" apply to every web client.

## 1. Structure

| Id | Applies when | Rule |
| --- | --- | --- |
| W-1 | | Feature-sliced modules: each feature owns its API calls, domain rules, hooks or stores, components, screens and tests behind a public index; routes or pages are thin. Cross-feature imports only through public indexes; the feature graph is acyclic and checked (C-16). Follow the framework's routing convention (file-based `app/` or `pages/`, or a router config) for where routes live. |
| W-2 | | A platform layer (HTTP client, telemetry, i18n, storage, auth session) never imports features. |
| W-3 | the framework renders on a server, or any secret exists | Server-only modules and secrets never reach the client bundle; the build fails on violation (for example `server-only` imports in Next.js, `.server` modules in Remix and SvelteKit). For a static SPA: the bundle contains no secret, only public configuration, checked in the gate. |

## 2. Data and state

| Id | Applies when | Rule |
| --- | --- | --- |
| W-4 | | One HTTP client module owns transport: base URL, credentials policy, request id, envelope and error parsing, `Retry-After`, session-invalidation handling. Response shapes come from the canonical schema (P-C2): generated types from the server's OpenAPI document, or the shared contracts package. Runtime parsing applies where C-02 requires it (version skew, third-party APIs, storage, values that reach money or authorisation). Raw `fetch` or axios calls outside this module are lint errors. |
| W-5 | | Server state lives in the data-fetching library the project uses (TanStack Query, SWR, RTK Query, framework loaders) with one key factory per feature; no retry on 4xx except one bounded retry on `429`; stale-while-revalidate for reads (P-P4). |
| W-6 | | Client state minimal and local; the URL is the source of truth for navigation state; no credential in URL state. |
| W-7 | browser storage is used | Storage reads parsed and discarded on failure (C-02); credentials in web storage only under P-S4 conditions; logout clears server-state caches and user storage. |

## 3. Errors and states

| Id | Applies when | Rule |
| --- | --- | --- |
| W-8 | | Each feature owns an error mapper: known code → user-facing string; server-authored message where the registry allows; otherwise a generic fallback. Raw exception messages are never rendered. Shared mappings (rate limited, offline, session invalid) apply first. |
| W-9 | | Every async view designs and tests the states that can occur: loading, empty, error, offline, forbidden, not-found, stale, and rate-limited or conflict where the API can return them. Stale or partial data is labelled with its age, never shown as live; failure is never rendered as zero. |
| W-10 | | Error boundaries render user-facing copy with a support or request reference; the exception goes to telemetry or the local log (P-O1, P-O4). |

## 4. Security mechanics

| Id | Applies when | Rule |
| --- | --- | --- |
| W-11 | the client runs an OAuth flow itself | Public client: PKCE S256, single-use `state` nonce, exact redirect matching (P-S2). Prefer a backend-for-frontend session where a server exists. |
| W-12 | | CSP with an explicit source list (P-S16); inline scripts via nonces or hashes; third-party scripts, fonts and widgets only from pinned origins, or none when the profile says the app is self-contained. |
| W-13 | telemetry or error tracking | Telemetry scrubs sensitive keys from URLs, paths, headers and breadcrumbs, with tests (C-05). |
| W-14 | uploads | Client-side type, size and count checks; the server stays authoritative (P-S15). |
| W-22 | user-supplied or fetched Markdown or HTML is rendered | Render through a sanitising renderer with raw HTML disabled, links restricted to safe schemes, and a test with a hostile payload (P-S12). |

## 5. Performance

| Id | Applies when | Rule |
| --- | --- | --- |
| W-15 | | Per-route first-load budget stored in the repository and enforced after build in the gate (P-P1). Starting targets for phone-first consumer apps: ≤ 300 KB gzipped per route, LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 on a mid-tier device; internal tools set their own, measured. |
| W-16 | | Heavy or rare modules (QR, PDF, charts, editors, provider widgets, telemetry SDK) lazy-loaded; motion honours reduced motion (P-P2). |
| W-17 | an image optimiser or remote images | Images sized and responsive; remote hosts allow-listed. |
| W-18 | | Fonts self-hosted or preconnected, swapped, subset to needed weights. |

## 6. Installable apps (PWA)

| Id | Applies when | Rule |
| --- | --- | --- |
| W-23 | a service worker exists | The worker caches the static shell and versioned assets only. Private API responses, documents, auth endpoints and user content are never cached unless an offline design approves it, and mutations are never queued or replayed offline unless designed under M-11 rules. A test asserts the cache allow-list. |
| W-24 | a service worker exists | Updates are explicit: new versions activate on a defined trigger, old caches are deleted, and logout clears caches that could hold user data. |
| W-25 | an install manifest exists | Manifest, icons and theme are complete; the offline state is a designed screen, not a browser error. |

## 7. Accessibility and localisation

| Id | Applies when | Rule |
| --- | --- | --- |
| W-19 | | WCAG 2.2 AA: one `h1` per screen, visible focus, labelled inputs, live regions on status, touch targets sized for the device class; automated checks on primary screens, human evidence where P-L1 requires it. |
| W-20 | | Strings externalised; `locales = many`: parity and growth tested, locale-aware formatting (P-L2). |
| W-21 | | Design tokens only; dark mode through tokens when supported (P-L3). |

## 8. Tests the web client owes

Unit tests for domain rules, mappers, parsers and key factories; component tests for every
designed state (W-9); a contract check between the client's types and the canonical schema;
end-to-end for critical journeys at the supported viewports; accessibility automation on
primary screens; visual regression where tokens drive surfaces; bundle budget after build;
service-worker cache allow-list test when W-23 applies.
