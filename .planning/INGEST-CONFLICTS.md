## Conflict Detection Report

### BLOCKERS (0)

No blockers detected. All ingested documents have high confidence classification, no cycle-detection failures, no locked-vs-locked ADR contradictions, and no contradictions with existing locked decisions in .planning/ context.

### WARNINGS (1)

[WARNING] Competing acceptance variants for bootstrap consolidation
  Found: FLOW_REVIEW.md (#2, #8) proposes extracting a shared `lib/bootstrap.sh` that both `matrix` and `scripts/common.sh` source. Variant A: "Have matrix source common.sh". Variant B: "Extract a shared lib/bootstrap.sh that both use".
  Expected: FIX-02 in existing REQUIREMENTS.md requires that "matrix sources scripts/common.sh for shared functions" — Variant A only, no mention of lib/bootstrap.sh.
  Impact: Both address the same scope (eliminate duplicated bootstrap code between matrix and common.sh) but diverge on implementation path. Variant A changes only matrix; Variant B creates a new library file and changes both consumers. Choosing wrong would require rework.
  → Choose one approach before routing. If the project prefers Variant A (keep common.sh as the shared bootstrap, source it from matrix), update FLOW_REVIEW items 2 and 8 to match. If Variant B (extract a new lib/bootstrap.sh), update FIX-02 in REQUIREMENTS.md to reference the new file instead.

### INFO (5)

[INFO] New workstream identified — scope divergence from completed milestone
  Note: The existing .planning milestone (Phases 1-4) covers Backend/Frontend Integration Overhaul and is marked COMPLETE in STATE.md. The three ingested documents (FLOW_REVIEW.md, DFD.md, IMPROVEMENT_PLAN.md) focus on Bash security hardening, structural cleanup of the matrix script, and shell testing — fundamentally different scope. This constitutes a new workstream, not a continuation of the existing phases.
  Source: STATE.md (milestone complete), PROJECT.md (integration scope), FLOW_REVIEW.md (security/structural scope), IMPROVEMENT_PLAN.md (new features scope)

[INFO] health-check --json extends existing API-01 coverage
  Note: FLOW_REVIEW.md (#5) requires `--json` support for health-check.sh. The existing API-01 requires `--json` for list, status, info, and check commands — but not health. No contradiction; FLOW_REVIEW #5 adds a new target not covered by API-01.
  Source: REQUIREMENTS.md API-01 (existing), FLOW_REVIEW.md #5 (ingested)

[INFO] Shell test coverage targets different domain than existing test requirements
  Note: FLOW_REVIEW.md (#14) requires shell script test coverage via bats for critical Bash paths (site creation, port allocation, validation). The existing TEST-01/TEST-02 require Jest-based unit tests for the API layer and integration tests for CLI JSON output. These target different codebases (Bash vs Node.js) and are complementary.
  Source: REQUIREMENTS.md TEST-01/TEST-02 (existing), FLOW_REVIEW.md #14 (ingested)

[INFO] IMPROVEMENT_PLAN features were out of scope for completed milestone
  Note: IMPROVEMENT_PLAN.md proposes features (SSL/TLS, dashboard auth, git deployment, multisite, container orchestration, monitoring) that the existing PROJECT.md explicitly listed as out of scope for the Backend/Frontend Integration Overhaul milestone. Since the milestone is complete, these proposals would require a new scope definition for a subsequent workstream — not a contradiction with currently active work.
  Source: PROJECT.md "Out of Scope" section (existing), IMPROVEMENT_PLAN.md (ingested)

[INFO] DFD.md provides architectural context with no decision assertions
  Note: DFD.md (DOC, precedence 1) describes the existing shell architecture data flow with no normative requirements or locked decisions. It documents the baseline for the proposed FLOW_REVIEW changes and does not conflict with any ingested or existing content.
  Source: DFD.md (ingested)
