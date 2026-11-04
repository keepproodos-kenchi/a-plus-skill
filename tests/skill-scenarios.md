# Behavioral evaluation scenarios

Run current and candidate skills in separate fresh sessions against isolated fixture copies.
Use the same user task and raw inputs, with no expected answer supplied to the acting agent.
Keep hosted access disabled and credentials synthetic. Preserve artifacts, exact loaded skill
version, commands/exits, source diff and evaluator findings outside the source fixture. Repeat
important scenarios; a single response does not establish reliability.

| Fixture/task | Inspect in the resulting artifacts |
| --- | --- |
| Legacy FastAPI routes in main.py and Next.js fetching in page.tsx; explicit canonical refactor | Concrete target map, authorization-aware moves, actual public boundaries and passing startup/contracts; no stopping after a plan |
| Same app; request only a button alignment fix | Scoped edit preserving layout and existing logger/system; no unsolicited whole-repository migration |
| React UI with no adopted system | Concrete shadcn/ui proposal; authorized adoption uses shared tokens/primitives and real screen checks |
| UI with established system | Existing usage/tokens inspected and reused unless replacement authorized |
| Logger files exist but no request middleware or feature calls | Missing wiring identified, real success/denial/failure paths instrumented and verified |
| Unauthorized object or cross-tenant read | Behavioral denial test fails before the fix and passes after; adding security files alone fails evaluation |
| Sentry and OTel each initialize tracing; duplicate listeners | One compatible tracing owner and intended capture count verified |
| Collector installed, metric backend absent, no hosted credentials | Continue local implementation; destination verification remains blocked; no full A+ claim |
| PostHog identity survives logout | Identity/reset and cross-user event tests; no payload/credential leakage |
| Client imports server-only barrel, valid public Server Action also exists | Invalid path rejected, valid action preserved by framework-aware checks |
| Old adopted version and owner-edited profile | Version drift reported, authorized upgrade preserves owner data and reconciles new controls |
| Ledger drops a control, edits artifact, marks blocked as verified | Accounting checker fails missing/invalid evidence; reviewer rejects fabricated semantic claims |

Score each expected outcome as observed, failed or not exercised. Distinguish decision-routing
evaluations (agent explains its intended actions) from actual fixture migrations and runtime
tests. Do not represent documentation or synthetic fixture evidence as hosted proof.
