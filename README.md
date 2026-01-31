# **Discourse Visible Permissions** Plugin

This plugin enables an infobox about configured permissions (who is allowed to create/respond/read) for categories.

## Features
- **Permission Table**: Displays who can see, reply, and create topics in a category.
- **Join/Request Action Buttons**:
  - `user-plus` icon: Join groups that allow public admission.
  - `paper-plane` icon: Request membership for groups that allow it.
- **Interactive Links**: Group names link directly to their respective group pages.
- **Localization**: Full support for German and English, including localized automatic group names (e.g., "jeder", "Team").
- **Automatic Detection**: Using `[show-permissions]` without a category ID inside a topic automatically detects the category from the topic.

## BBCode

Use:

```
[show-permissions]

[show-permissions category=123]
```

## Current Status

- API endpoint implemented for per-category permissions (logged-in + can see category).
- BBCode `[show-permissions]` emits a placeholder element and renders data from the endpoint.

## Usage

Example BBCode:
- `[show-permissions category=5]`
- `[show-permissions category=5 view="short"]` (Available views: `table`, `short`)
- `[show-permissions category=5 class="custom-class"]`
- `[show-permissions]` (automatically detects the current category when used inside a topic)

## Configuration

You can set the default view for all `[show-permissions]` tags in the site settings:
- `discourse_visible_permissions_default_view`: Choose between `table` (default) and `short`.

## Rake Tasks

### Append tag to all category descriptions

To automatically add the `[show-permissions]` tag to all existing category description topics (the "About the... category" topics), you can run:

```bash
rake discourse_visible_permissions:append_to_categories
```

This task will scan all categories and append the tag to the first post of the category's definition topic if it's not already present.


## API

- **Endpoint:** `GET /c/:category_id/permissions`
- **Auth:** logged-in users only; must be able to see the category. If the user is not logged in or doesn't have access, the BBCode tag will be automatically hidden.
- **Response:**
  ```json
  {
    "category_id": 1,
    "category_name": "General",
    "group_permissions": [
      {
        "permission_type": 1,
        "permission": "full",
        "group_name": "admins",
        "group_display_name": "Admins",
        "group_id": 1,
        "can_join": false,
        "can_request": false,
        "is_member": false,
        "group_url": "/g/admins"
      }
    ]
  }
  ```

