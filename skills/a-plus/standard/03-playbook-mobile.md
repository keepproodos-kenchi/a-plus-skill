# Layer 3 — Mobile Playbook (iOS and Android)

**Status:** Reference v1.1. Stack mechanics for native and cross-platform apps. Binds to Layer 1 and 2 controls.

## 1. Security mechanics

| Id | Rule |
| --- | --- |
| M-1 | Secrets and tokens in the platform secure store (Keychain, Keystore-backed storage), never in plain files, preferences, logs or crash reports; biometric or device-credential gating for high-value actions (P-S5). |
| M-2 | TLS only with system certificate validation; certificate pinning only with a rotation plan and a remote kill switch; no cleartext traffic. |
| M-3 | OAuth as a public client through the system browser or an external user-agent (RFC 8252): PKCE S256, `state` nonce, app-link or custom-scheme redirect verified (P-S2). |
| M-4 | App integrity attestation (App Attest, Play Integrity) where the threat model requires it; trust tiers scale server limits; failure degrades, never silently passes (P-S6). |
| M-5 | Deep links and app links verified through associated domains and asset links; every inbound link validated against an allow-list; auth callbacks carry a nonce the app issued and consume it once. |
| M-6 | Crash and performance telemetry scrubs personal data and credentials (C-05); breadcrumbs never carry tokens. |

## 2. Compatibility and release

| Id | Rule |
| --- | --- |
| M-7 | Semantic app version plus build number; the server enforces a minimum supported version with a forced-upgrade screen; the API compatibility window is documented and tested against the oldest supported build (P-C3). |
| M-8 | Installed clients cannot be rolled back: staged rollouts with a measurement window and sample size defined in the profile, halt criteria on crash-free sessions and key journey success, server-side kill switches for risky features (P-X2). |
| M-9 | Release health gate: crash-free sessions and journey success above the profile threshold over the measurement window before expanding rollout. |
| M-10 | Privacy manifests and store data-safety declarations generated from the data catalogue and SDK inventory, reviewed per release (P-V7). |

## 3. Offline, sync and background

| Id | Rule |
| --- | --- |
| M-11 | Offline support is scoped to journeys where it earns its complexity (browsing, drafting, explicitly designed queued writes). Server-authoritative operations, payments above all, are never offline-authoritative: they are queued offline only where the design explicitly approves it, with an idempotency key, visible pending state and server-side revalidation of the queued intent when processed; otherwise the app refuses the action offline with a clear state. |
| M-12 | Queued mutations carry idempotency keys (C-08); conflict resolution rules are defined per entity; sync status is visible. |
| M-13 | Background work is bounded, battery-aware, cancellable and resumable; push payloads carry no sensitive data; permissions requested in context. |

## 4. Performance

| Id | Rule |
| --- | --- |
| M-14 | Budgets in the profile: cold start on the minimum supported device, app size per platform, memory, battery and data usage for background work (P-P1), measured with the platform profiler. |
| M-15 | Lists virtualised; images sized and cached; heavy modules loaded on demand. |

## 5. Accessibility and localisation

| Id | Rule |
| --- | --- |
| M-16 | Platform accessibility APIs: labels, traits, dynamic type, contrast, reduced motion; screen-reader pass on primary journeys per release (P-L1). |
| M-17 | Strings externalised with locale parity; pluralisation and right-to-left handled by platform facilities (P-L2). |

## 6. Tests the mobile app owes

Unit for domain rules, parsers and mappers; widget or view tests for every designed state; integration tests for secure storage, sync queue, idempotency and conflict resolution; contract tests against the canonical schema; UI journey tests on the minimum supported OS; accessibility audit on primary journeys; compatibility tests against the oldest supported API version; release health dashboards wired before first staged rollout.
