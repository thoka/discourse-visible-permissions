# **Discourse Visible Permissions** Plugin

**Plugin Summary**

This plugin enables an infobox about configured permissions (who is allowed to create/respond/read in each category).
For more information, please see: **TODO: add meta topic URL**

## Plan

1. **Tests & mocks**
        - [x] API tests for the per-category permissions endpoint (authenticated users).
        - [x] BBCode rendering tests for `[show-permissions category=ID]`.
        - [x] Frontend mocks (Pretender) for `/c/:category_id/permissions.json`.
2. **Build the display**
        - [x] Register a custom BBCode that outputs a raw JSON view.
        - [x] Render raw data fetched from the per-category endpoint.
3. **Replace mocks with real data**
        - [x] Endpoint returns real category permissions.
        - [x] Frontend consumes the endpoint instead of mocks.
        - [x] Update relevant tests to use real data.

## API

- **Endpoint:** `GET /c/:category_id/permissions`
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
[show-permissions category=123]
```

## Current Status

- API endpoint implemented for per-category permissions (logged-in + can see category).
- BBCode `[show-permissions]` emits a placeholder element and renders data from the endpoint.

## Usage

Example BBCode:
- `[show-permissions category=5]`
- `[show-permissions category=5 class="custom-class"]`
- `[show-permissions]` (automatically detects the current category when used inside a topic)

## Rake Tasks

### Append tag to all category descriptions

To automatically add the `[show-permissions]` tag to all existing category description topics (the "About the... category" topics), you can run:

```bash
rake discourse_visible_permissions:append_to_categories
```

This task will scan all categories and append the tag to the first post of the category's definition topic if it's not already present.
