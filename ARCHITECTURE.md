# Architecture Overview: Discourse Visible Permissions

This plugin provides a dynamic info box for category permissions, integrated via BBCode.

## Core Flow
1. **Frontend Decoration**: `assets/javascripts/discourse/initializers/discourse-visible-permissions.js` uses `api.decorateCookedElement` to find `[show-permissions]` placeholders.
2. **Data Fetch**: It calls `GET /c/:id/permissions.json`, handled by `PermissionsController#show`.
3. **Broadened Access**: The controller checks if a user meets `min_trust_level`. Even if a user cannot "see" a category (restricted content), metadata is returned if at least one associated group is joinable/requestable.
4. **Data Aggregation**: `PermissionsFetcher` (Service) gathers category groups, permission types, and user membership status. It sorts permissions by hierarchy (highest access level first) and then by group name.
5. **Dynamic Rendering**: The initializer renders the localized UI in three distinct views:
   - `table` (Default): Modern hierarchical view showing highest permission only via color-coded badges.
   - `classic`: Full matrix view showing See/Reply/Create status checkboxes.
   - `short`: Iconic view grouping groups by their maximum permission level.

## Key Components
- **BBCode**: Handled via `lib/discourse_markdown/discourse-visible-permissions.rb`.
- **Backend API**: Rails Engine routing in `config/routes.rb`.
- **Permissions Service**: `app/services/discourse_visible_permissions/permissions_fetcher.rb`.
- **Styling**: `assets/stylesheets/discourse-visible-permissions.scss` (supports configurable colors via site settings).

## Data Model Reliance
- **CategoryGroup**: Primary source for mapping `category_id` -> `group_id` -> `permission_type` (1:Full, 2:Create/Reply, 3:Read).
- **Group Settings**: Checks `public_admission` and `allow_membership_requests`.
