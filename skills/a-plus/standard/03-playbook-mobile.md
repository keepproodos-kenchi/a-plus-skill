# Layer 3 — Mobile Playbook (iOS and Android)

**Status:** Reference v2.0. Applies when `roles` includes `mobile`: native (Swift, Kotlin) and
cross-platform (React Native, Expo, Flutter) apps distributed as installed binaries. An
installable PWA uses the web playbook. Binds to Layer 1 and 2 controls. Rows without an
"Applies when" apply to every mobile app.

## 0. Structure

| Id | Applies when | Rule |
| --- | --- | --- |
| M-18 | | Feature modules with the same rules as W-1 and W-2: each feature owns its API calls, state, screens and tests behind a public interface; a platform layer (networking, secure storage, telemetry, navigation) never imports features; the graph is checked (C-16). Follow the platform's convention: Swift packages or targets, Gradle modules, Expo Router or a navigator config, Flutter `lib/features/…`. |
| M-19 | | Networking and errors follow W-4 and W-8; server state follows W-5 using the library the app already uses. Runtime parsing of responses is required (C-02): installed clients outlive server versions. |

## 1. Security mechanics

| Id | Applies when | Rule |
| --- | --- | --- |
| M-1 | | Secrets and tokens in the platform secure store (Keychain, Keystore-backed storage), never in plain files, preferences, logs or crash reports; biometric or device-credential gating for high-value actions (P-S5). |
| M-2 | | TLS only with system certificate validation; certificate pinning only with a rotation plan and a remote kill switch; no cleartext traffic. |
| M-3 | the app signs users in | OAuth as a public client through the system browser (RFC 8252): PKCE S256, `state` nonce, verified app-link or custom-scheme redirect (P-S2). |
| M-4 | the threat model needs client trust | App integrity attestation (App Attest, Play Integrity); trust tiers scale server limits; failure degrades, never silently passes (P-S6). |
| M-5 | deep links | Verified through associated domains and asset links; every inbound link validated against an allow-list; auth callbacks carry a single-use nonce the app issued. |
| M-6 | | Crash and performance telemetry scrubs personal data and credentials (C-05); breadcrumbs never carry tokens. |

## 2. Compatibility and release

| Id | Applies when | Rule |
| --- | --- | --- |
| M-7 | | Semantic app version plus build number; the server enforces a minimum supported version with a forced-upgrade screen; the API compatibility window is documented and tested against the oldest supported build (P-C3). |
| M-8 | `delivery = app-store` | Installed clients cannot be rolled back: staged rollouts with a measurement window and sample size in the profile, halt criteria on crash-free sessions and key journey success, server-side kill switches for risky features (P-X2). |
| M-9 | `delivery = app-store` | Release health gate: crash-free sessions and journey success above the profile threshold before expanding rollout. |
| M-10 | `delivery = app-store` | Privacy manifests and store data-safety declarations generated from the data catalogue and SDK inventory, reviewed per release (P-V7). |

## 3. Offline, sync and background

| Id | Applies when | Rule |
| --- | --- | --- |
| M-11 | offline support exists | Offline scoped to journeys where it earns its complexity (browsing, drafting, explicitly designed queued writes). Server-authoritative operations, payments above all, are never offline-authoritative: queued only where the design approves it, with an idempotency key, visible pending state and server-side revalidation; otherwise the app refuses the action offline with a clear state. |
| M-12 | queued mutations | Idempotency keys (C-08); conflict resolution defined per entity; sync status visible. |
| M-13 | background work or push | Bounded, battery-aware, cancellable and resumable; push payloads carry no sensitive data; permissions requested in context. |

## 4. Performance

| Id | Applies when | Rule |
| --- | --- | --- |
| M-14 | | Budgets in the profile: cold start on the minimum supported device, app size per platform, memory, battery and data use for background work (P-P1), measured with the platform profiler. |
| M-15 | | Lists virtualised; images sized and cached; heavy modules loaded on demand. |

## 5. Accessibility and localisation

| Id | Applies when | Rule |
| --- | --- | --- |
| M-16 | | Platform accessibility APIs: labels, traits, dynamic type, contrast, reduced motion; screen-reader pass on primary journeys per release when P-L1 requires human evidence. |
| M-17 | | Strings externalised; `locales = many`: parity, pluralisation and right-to-left through platform facilities (P-L2). |

## 6. Tests the mobile app owes

Unit for domain rules, parsers and mappers; widget or view tests for every designed state;
integration tests for secure storage, sync queue, idempotency and conflict resolution;
contract tests against the canonical schema; UI journey tests on the minimum supported OS;
accessibility audit on primary journeys; compatibility tests against the oldest supported
API version; release health dashboards wired before the first staged rollout.
