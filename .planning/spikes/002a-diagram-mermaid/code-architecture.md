# Code Architecture Diagram

Shows only code/source files (`.js`, `.sh`) — excludes planning docs and markdown.

```mermaid
graph TB
  subgraph FRONTEND["Frontend (JavaScript)"]
    FE0["public/js/app.js"]
    FE0_meta["61 funcs, 76 calls"]
    style FE0_meta fill:#e0e0e0,stroke:#999
    FE1["app.js"]
    FE1_meta["18 funcs, 5 calls"]
    style FE1_meta fill:#e0e0e0,stroke:#999
    FE2["__tests__/app.test.js"]
    FE2_meta["1 funcs, 0 calls"]
    style FE2_meta fill:#e0e0e0,stroke:#999
  end
  subgraph BACKEND["Backend (Bash Scripts)"]
    BE0["matrix.sh"]
    BE0_meta["50 funcs, 141 calls"]
    style BE0_meta fill:#e0e0e0,stroke:#999
    BE1["scripts/compose-lib.sh"]
    BE1_meta["10 funcs, 8 calls"]
    style BE1_meta fill:#e0e0e0,stroke:#999
    BE2["scripts/common.sh"]
    BE2_meta["8 funcs, 4 calls"]
    style BE2_meta fill:#e0e0e0,stroke:#999
    BE3["scripts/helpers.sh"]
    BE3_meta["6 funcs, 2 calls"]
    style BE3_meta fill:#e0e0e0,stroke:#999
    BE4["config/validation.sh"]
    BE4_meta["5 funcs, 2 calls"]
    style BE4_meta fill:#e0e0e0,stroke:#999
    BE5["scripts/cache-clear.sh"]
    BE5_meta["3 funcs, 3 calls"]
    style BE5_meta fill:#e0e0e0,stroke:#999
    BE6["scripts/update-core.sh"]
    BE6_meta["2 funcs, 2 calls"]
    style BE6_meta fill:#e0e0e0,stroke:#999
    BE7["scripts/backup.sh"]
    BE7_meta["2 funcs, 2 calls"]
    style BE7_meta fill:#e0e0e0,stroke:#999
    BE8["scripts/clone.sh"]
    BE8_meta["1 funcs, 1 calls"]
    style BE8_meta fill:#e0e0e0,stroke:#999
    BE9["scripts/reset.sh"]
    BE9_meta["1 funcs, 1 calls"]
    style BE9_meta fill:#e0e0e0,stroke:#999
    BE10["scripts/search-replace.sh"]
    BE10_meta["1 funcs, 1 calls"]
    style BE10_meta fill:#e0e0e0,stroke:#999
  end
  app.js_app.js["app.js → app.js"]
  style app.js_app.js fill:#fff,stroke:#999,stroke-dasharray:4
  app.js --> app.js
```

## Code File Summary

| File | Functions | Calls | Community |
|------|-----------|-------|-----------|
| frontend/public/js/app.js | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 0 |
| scripts/graphify-shim/matrix.sh | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 1 |
| frontend/app.js | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 2 |
| scripts/compose-lib.sh | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 28 |
| scripts/common.sh | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 34 |
| scripts/helpers.sh | [object Object],[object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 43 |
| config/validation.sh | [object Object],[object Object],[object Object],[object Object],[object Object] | undefined | 52 |
| scripts/cache-clear.sh | [object Object],[object Object],[object Object] | undefined | 62 |
| scripts/update-core.sh | [object Object],[object Object] | undefined | 71 |
| scripts/backup.sh | [object Object],[object Object] | undefined | 70 |
| frontend/__tests__/app.test.js | [object Object] | undefined | 23 |
| scripts/clone.sh | [object Object] | undefined | 78 |
| scripts/reset.sh | [object Object] | undefined | 79 |
| scripts/search-replace.sh | [object Object] | undefined | 80 |