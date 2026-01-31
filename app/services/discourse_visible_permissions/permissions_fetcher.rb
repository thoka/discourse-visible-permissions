# frozen_string_literal: true

module DiscourseVisiblePermissions
  class PermissionsFetcher
    include Service::Base

    step :build_permissions

    private

    def build_permissions(category:, guardian:)
      permissions =
        category
          .category_groups
          .joins(:group)
          .includes(:group)
          .merge(Group.visible_groups(guardian.user, "groups.name ASC", include_everyone: true))
          .map do |category_group|
            {
              permission_type: category_group.permission_type,
              permission: CategoryGroup.permission_types.key(category_group.permission_type),
              group_name: category_group.group.name,
              group_display_name: group_display_name(category_group.group),
              group_id: category_group.group_id,
            }
          end

      if !category.read_restricted &&
           !permissions.any? { |p| p[:group_id] == Group::AUTO_GROUPS[:everyone] }
        everyone_group = Group[:everyone]
        permissions.unshift(
          {
            permission_type: CategoryGroup.permission_types[:create_post],
            permission: "create_post",
            group_name: everyone_group&.name || "everyone",
            group_display_name: group_display_name(everyone_group) || "everyone",
            group_id: Group::AUTO_GROUPS[:everyone],
          },
        )
      end

      context[:permissions] = permissions
    end

    def group_display_name(group)
      return nil if group.nil?
      return group.full_name if group.full_name.present?

      if group.automatic
        I18n.t("groups.default_names.#{group.name}", default: group.name)
      else
        group.name
      end
    end
  end
end
