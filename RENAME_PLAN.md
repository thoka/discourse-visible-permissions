# Renaming Plan: From Permissions to Outreach

This document outlines the steps to pivot the plugin's identity to **Visible Outreach**, reflecting its focus on transparency and audience reach (Σ).

## Phase 1: Metadata & Ruby Namespace
- [ ] **plugin.rb**: Update `name` to `discourse-visible-outreach`.
- [ ] **Ruby Classes**: Rename the base module `DiscourseVisiblePermissions` to `DiscourseVisibleOutreach`.
- [ ] **File Paths**: Move `app/services/discourse_visible_permissions` to `app/services/discourse_visible_outreach`, etc.
- [ ] **Site Settings**: Rename `discourse_visible_permissions_enabled` to `discourse_visible_outreach_enabled`.

## Phase 2: Frontend Integration
- [ ] **Initializer**: Rename to `discourse-visible-outreach.js`. Update the registration name in `api.renderInOutlet`.
- [ ] **Components**: Rename `visible-permissions-table` to `visible-outreach-table`.
- [ ] **BBCode**: Add `[show-outreach]` as the primary tag. Keep `[show-permissions]` as a deprecated alias.

## Phase 3: Assets & Translations
- [ ] **YAML**: Move all keys from `js.discourse_visible_permissions` to `js.discourse_visible_outreach`.
- [ ] **SCSS**: Rename CSS classes (e.g., `.visible-permissions-table` -> `.visible-outreach-table`).

## Phase 4: Migration
- [ ] **Data Migration**: Create a migration to copy existing site settings values from the old keys to the new keys.
- [ ] **Rake Task**: Update the task to include the new BBCode name.

## Status: Postponed
This plan is documented but implementation is on hold to maintain stability during current development.