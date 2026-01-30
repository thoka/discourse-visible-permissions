# **Discourse Visible Rights** Plugin

**Plugin Summary**

This plugin enables an infobox about configured rights (who is allowed to create/respond/read in each category).

For more information, please see: **TODO: add meta topic URL**

## Plan

1. **Tests & mocks**
	- [ ] API tests for the per-category rights endpoint (authenticated users).
	- [ ] BBCode rendering tests for `[visible-rights category=ID]`.
	- [ ] Frontend mocks (Pretender) for `/c/:category_id/visible-rights.json`.
2. **Build the display**
	- [ ] Register a custom BBCode that outputs a raw JSON view.
	- [ ] Render raw data fetched from the per-category endpoint.
3. **Replace mocks with real data**
	- [ ] Endpoint returns real category rights.
	- [ ] Frontend consumes the endpoint instead of mocks.
	- [ ] Update relevant tests to use real data.

## API

- **Endpoint:** `GET /c/:category_id/visible-rights.json`
- **Auth:** logged-in users only; must be able to see the category
- **Response:**
  ```json
  {
    "category_id": 1,
    "group_permissions": [
      {
        "permission_type": 2,
        "permission": "create_post",
        "group_name": "staff",
        "group_id": 3
      }
    ]
  }
  ```

## BBCode

Use:

```
[visible-rights category=123]
```

## Current Status

- API endpoint implemented for per-category rights (logged-in + can see category).
- BBCode emits a placeholder element and renders raw JSON from the endpoint.
- Request spec, PrettyText spec, and Pretender mock added.

## Next Steps

- Rebuild the dev container to resolve current Zeitwerk boot issues before re-running specs.
- Run plugin specs via `bin/rake plugin:turbo_spec['discourse-visible-rights','--verbose --format=progress --use-runtime-info --profile=50']`.
- Decide whether raw JSON output is sufficient or replace with the admin-config widget.

