# frozen_string_literal: true

module DiscourseVisiblePermissions
  class PermissionsController < ::ApplicationController
    requires_plugin DiscourseVisiblePermissions::PLUGIN_NAME
    requires_login

    def show
      raise Discourse::NotFound unless SiteSetting.discourse_visible_permissions_enabled
      raise Discourse::InvalidAccess if current_user.trust_level < SiteSetting.discourse_visible_permissions_min_trust_level

      category = Category.find_by(id: params[:category_id])
      raise Discourse::NotFound if category.blank?

      unless guardian.can_see?(category)
        # Check if there's any group the user could join/request to gain access
        can_join_any = category.category_groups.joins(:group).where(
          "groups.public_admission = ? OR groups.allow_membership_requests = ?", true, true
        ).exists?

        raise Discourse::NotFound unless can_join_any
      end

      result = PermissionsFetcher.call(category: category, guardian: guardian)

      render json: {
               category_id: category.id,
               category_name: category.name,
               category_url: category.url,
               group_permissions: result.permissions,
             }
    end
  end
end
