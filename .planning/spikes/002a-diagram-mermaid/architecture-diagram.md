# Architecture Diagram

```mermaid
graph TB
  subgraph S0["Community 0 (62 nodes)"]
    F0_frontend_public_js_app_js["frontend/public/js/app.js"]
  end
  subgraph S1["Community 1 (52 nodes)"]
    F1_scripts_graphify_shim_matrix_s["scripts/graphify-shim/matrix.sh"]
  end
  subgraph S2["Community 2 (48 nodes)"]
    F2_frontend_app_js["frontend/app.js"]
  end
  subgraph S3["Community 3 (28 nodes)"]
    F3__planning_codebase_CONVENTIONS[".planning/codebase/CONVENTIONS.md"]
  end
  subgraph S4["Community 4 (28 nodes)"]
    F4__planning_REQUIREMENTS_md[".planning/REQUIREMENTS.md"]
  end
  subgraph S5["Community 5 (26 nodes)"]
    F5__planning_codebase_CONCERNS_md[".planning/codebase/CONCERNS.md"]
  end
  subgraph S6["Community 6 (26 nodes)"]
    F6_frontend_package_json["frontend/package.json"]
  end
  subgraph S7["Community 7 (23 nodes)"]
    F7_IMPROVEMENT_PLAN_md["IMPROVEMENT_PLAN.md"]
  end
  subgraph S8["Community 8 (23 nodes)"]
    F8__planning_research_260406_enha["...nning/research/260406-enhancements.md"]
  end
  subgraph S9["Community 9 (20 nodes)"]
    F9__planning_phases_01_structured["...es/01-structured-api-layer/02-PLAN.md"]
  end
  frontend_public_js_app_js --> frontend_app_js
  scripts_compose_lib_sh["scripts/compose-lib.sh"]
  scripts_common_sh["scripts/common.sh"]
  scripts_helpers_sh["scripts/helpers.sh"]
  config_validation_sh["config/validation.sh"]
  _planning_phases_01_structured_api_layer["...nning/phases/01-structured-api-layer/01-PLAN.md"]
  scripts_cache_clear_sh["scripts/cache-clear.sh"]
  scripts_update_core_sh["scripts/update-core.sh"]
  scripts_backup_sh["scripts/backup.sh"]
  _planning_phases_03_testing_quality_ui_0[".planning/phases/03-testing-quality-ui/02-PLAN.md"]
  frontend___tests___app_test_js["frontend/__tests__/app.test.js"]
  scripts_clone_sh["scripts/clone.sh"]
  scripts_reset_sh["scripts/reset.sh"]
  scripts_search_replace_sh["scripts/search-replace.sh"]
  _planning_phases_02_real_time_websocket_[".planning/phases/02-real-time-websocket/01-PLAN.md"]
```

## File Statistics

| File | Functions | Calls | Community |
|------|-----------|-------|-----------|
| frontend/public/js/app.js | 61 | 76 | 0 |
| scripts/graphify-shim/matrix.sh | 50 | 141 | 1 |
| frontend/app.js | 18 | 5 | 2 |
| scripts/compose-lib.sh | 10 | 8 | 28 |
| scripts/common.sh | 8 | 4 | 34 |
| scripts/helpers.sh | 6 | 2 | 43 |
| config/validation.sh | 5 | 2 | 52 |
| .planning/phases/01-structured-api-layer/01-PLAN.md | 4 | 0 | 16 |
| scripts/cache-clear.sh | 3 | 3 | 62 |
| scripts/update-core.sh | 2 | 2 | 71 |
| scripts/backup.sh | 2 | 2 | 70 |
| .planning/phases/03-testing-quality-ui/02-PLAN.md | 2 | 0 | 25 |
| frontend/__tests__/app.test.js | 1 | 0 | 23 |
| scripts/clone.sh | 1 | 1 | 78 |
| scripts/reset.sh | 1 | 1 | 79 |

## Call Graph Summary
- **Total call edges:** 248
- **Define edges:** 93
- **Import edges:** 7
- **Files with functions/calls:** 19
- **Total source files in graph:** 69