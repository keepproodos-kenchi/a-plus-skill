# Layer 3 — Web Frontend Playbook

**Status:** Reference v1.1. Stack mechanics for browser applications. Binds to Layer 1 and 2 controls.

## 1. Structure

| Id | Rule |
| --- | --- |
| W-1 | Feature-sliced modules: each feature owns its API client, domain rules, hooks or stores, components, screens, storage adapters and tests behind a public index; routes are thin (B-4 equivalent). Cross-feature imports only through public indexes; the feature graph is acyclic and lint-checked. |
| W-2 | Platform layer (HTTP client, telemetry, i18n, storage) never imports features. |
| W-3 | Server versus client boundary explicit; server-only modules and secrets never reach the client bundle; the build fails on violation. |

## 2. Data and state

| Id | Rule |
| --- | --- |
| W-4 | One HTTP client owns transport: request id, credentials policy, envelope parsing, schema validation (C-02), `Retry-After` parsing, session-invalidation signals. Raw network calls elsewhere are lint errors. |
| W-5 | Server state lives in a fetching library with exported cache-key factories; dedupe on mount; no retry on 4xx except one bounded retry on `429`; stale-while-revalidate for reads (P-P4). |
| W-6 | Client state minimal and local; the URL is the source of truth for navigation state; no credential in URL state. |
| W-7 | Storage reads parsed and discarded on failure (C-02); credentials in web storage only under P-S4 conditions. |

## 3. Errors and states

| Id | Rule |
| --- | --- |
| W-8 | Each feature owns a customer-facing error mapper: known code → localised string; server-authored message when the registry allows; otherwise a generic fallback. Raw exception messages are never rendered. Shared mappings (rate limited, offline, session invalid) apply first. |
| W-9 | Every async view designs and tests: loading, empty, error, offline, rate-limited, forbidden, not-found, stale, conflict. |
| W-10 | Error boundaries render localised copy with a support reference; the exception goes only to telemetry (P-O4). |

## 4. Security mechanics

| Id | Rule |
| --- | --- |
| W-11 | OAuth as a public client: PKCE S256, random single-use `state` nonce stored in the session, exact redirect matching, system browser for native shells (P-S2). |
| W-12 | CSP enforced with an explicit source list (P-S16); inline scripts via nonces or hashes; third-party widgets loaded from pinned origins. |
| W-13 | Telemetry scrubs sensitive keys from URLs, paths, headers and breadcrumbs with tests (C-05). |
| W-14 | Uploads validated client-side for type, size and count atomically; the server remains authoritative (P-S15). |

## 5. Performance

| Id | Rule |
| --- | --- |
| W-15 | Per-route first-load budget stored in the repository and enforced after build in CI (P-P1); starting target for phone-first consumer apps: ≤ 300 KB gzipped per route, LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 on a mid-tier device over 3G, confirmed by field data. |
| W-16 | Heavy or rare modules (QR, PDF, charts, editors, provider widgets, telemetry SDK) lazy-loaded; animation libraries off hot paths; CSS transitions honour reduced motion (P-P2). |
| W-17 | Images sized and responsive through an optimiser with allow-listed production hosts; the production build fails when the host list is empty. |
| W-18 | Fonts self-hosted or preconnected, swapped, subset to needed weights. |

## 6. Accessibility and localisation

| Id | Rule |
| --- | --- |
| W-19 | WCAG 2.2 AA: one `h1` per screen, visible focus, labels on inputs, live regions on status, touch targets sized for the device class; automated checks plus human keyboard and screen-reader evidence on primary journeys (P-L1). |
| W-20 | Strings externalised with locale parity; longest-locale growth tested; locale-aware formatting (P-L2). |
| W-21 | Design tokens only; dark mode through tokens when supported (P-L3). |

## 7. Tests the web app owes

Unit for domain rules, mappers, parsers and key factories; component tests for every designed state; contract tests against the canonical schema for every API client; end-to-end for critical journeys; accessibility automation on primary screens; visual regression on token-driven surfaces; bundle budget check after build.
