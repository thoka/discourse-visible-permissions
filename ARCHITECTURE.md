# Architecture Overview: Discourse Visible Permissions

This plugin provides a dynamic info box for category permissions, integrated via BBCode.

## Core Flow
1. **Frontend Decoration**: `assets/javascripts/discourse/initializers/discourse-visible-permissions.js` uses `api.decorateCookedElement` to find `[show-permissions]` placeholders.
2. **Data Fetch**: It calls `GET /c/:id/permissions.json`, handled by `PermissionsController#show`.
3. **Broadened Access**: The controller checks if a user meets `min_trust_level`. Even if a user cannot "see" a category (restricted content), metadata is returned if at least one associated group is joinable/requestable.
4. **Data Aggregation**: `PermissionsFetcher` (Service) gathers category groups, permission types, and user membership status.
5. **Dynamic Rendering**: The initializer renders the localized UI in either `table` (Discourse-style list) or `short` (icon-grouped) view.

## Key Components
- **BBCode**: Handled via `lib/discourse_markdown/discourse-visible-permissions.rb`.
- **Backend API**: Rails Engine routing in `config/routes.rb`.
- **Permissions Service**: `app/services/discourse_visible_permissions/permissions_fetcher.rb` (calculates `can_join`, `can_request` flags).
- **Styling**: `assets/stylesheets/discourse-visible-permissions.scss` (explicitly registered in `plugin.rb`).

## Data Model Reliance
- **CategoryGroup**: Primary source for mapping `category_id` -> `group_id` -> `permission_type` (1:Full, 2:Create/Reply, 3:Read).
- **Group Settings**: Checks `public_admission` and `allow_membership_requests`.
