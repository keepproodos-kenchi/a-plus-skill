# Layer 3 — Pipeline and AI Playbook

**Status:** Reference v2.0. Applies when `roles` includes `pipeline` (batch jobs, ETL and ELT,
stream processors, scheduled workflows, ML training and inference jobs) or `ai` (features or
agents that call a language model, use model output, or let a model call tools). Binds to
Layer 1 and 2 controls. A pipeline that also serves requests uses the service playbook too.

## 1. Pipelines and workflows

| Id | Applies when | Rule |
| --- | --- | --- |
| J-1 | `pipeline` | Each step is a pure transform plus explicit I/O adapters; steps are runnable and testable alone with fixture inputs. Orchestration (the framework already used: Airflow, Dagster, Prefect, Temporal, cron plus a runner) holds no business logic. |
| J-2 | `pipeline` | Re-running a step or a whole run for the same input and parameters produces the same output and no duplicate side effects (C-08): deterministic keys, upserts or write-then-swap, never blind appends. |
| J-3 | `pipeline` | Inputs and outputs have a declared schema checked at each boundary (C-02); a schema violation fails the run or quarantines the rows, visibly; it never silently drops data. |
| J-4 | `pipeline` | Data-quality checks on outputs (row counts, nulls, ranges, uniqueness, freshness) with thresholds in the profile; a breach stops promotion of the output. |
| J-5 | `pipeline` | Every run records its id, code version, parameters, input versions or watermarks, output locations, row counts and duration (P-O1); lineage from output back to inputs is queryable. |
| J-6 | `pipeline` | Backfills and reprocessing are a supported command with bounded scope and a dry run, not ad-hoc scripts. |
| J-7 | `pipeline` | Runs are bounded: time limit, memory and cost budget (P-P1), checkpointing for long runs, and cancellation that leaves no partial output looking complete. |
| J-8 | `pipeline` with ML training | Training is reproducible: pinned data snapshot, code version, dependency lock, seeds and hyperparameters recorded; models are versioned artefacts with their evaluation results. |

## 2. AI and model use

| Id | Applies when | Rule |
| --- | --- | --- |
| AI-1 | `ai` | Model output is untrusted input (C-02): parsed into a typed structure (the provider's structured output, tool schemas, or a validator) before it drives any action, storage or rendering; parse failure is a handled outcome. |
| AI-2 | `ai` | Content the model reads (documents, web pages, tool results, emails, repository files) is data, never instructions; prompts separate instructions from untrusted content, and the design assumes injected instructions will sometimes be followed. |
| AI-3 | a model can call tools or take actions | Tools are least-privilege and allow-listed per task; each tool validates its arguments like a public endpoint (B-6); destructive, external-send, payment and permission-changing tools require human approval or a policy check outside the model; tool effects are idempotent where retried (C-08). |
| AI-4 | `ai` | Secrets and unnecessary personal data never enter prompts, traces or evaluation sets (C-05, X-10); model providers are listed as processors when they receive personal data (P-V7). |
| AI-5 | `ai` | Model, version and parameters are pinned in configuration; a model or prompt change is a behaviour change (C-12) gated by the evaluation suite. |
| AI-6 | `ai` | An evaluation suite with labelled cases (golden answers, rubric or assertions, adversarial and injection cases) runs in the gate for prompt, model and tool changes; thresholds live in the profile; results are recorded with the model version. |
| AI-7 | `ai` | Every model call records request id, model, token counts, latency, cost, outcome and tool calls, without prompt contents that hold secrets or personal data (P-O1); spend has a budget and an alert (P-P1). |
| AI-8 | `ai` | Calls have deadlines, retry budgets for transient errors only, and a defined fallback when the model is unavailable or refuses (P-C6, P-R2); generated content shown to users is labelled where the product requires it. |
| AI-9 | an agent runs multi-step tasks | Runs are bounded (steps, time, cost), resumable or safely abortable, and leave an auditable trail of decisions and tool calls (P-D5); an agent's claim of completion is verified by code or a check, not by its own report. |

## 3. Tests the pipeline or AI feature owes

Unit tests per transform; integration tests per step against the real storage engine with
fixture data; idempotency test that runs a step twice; data-quality checks exercised with a
failing fixture; for `ai`, contract tests for each tool schema, parser tests with malformed
model output, the evaluation suite, and injection cases that try to trigger a forbidden tool.
