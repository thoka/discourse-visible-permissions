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
              group_id: category_group.group_id,
            }
          end

      if permissions.empty? && !category.read_restricted
        permissions << {
          permission_type: CategoryGroup.permission_types[:full],
          permission: "full",
          group_name: Group[:everyone]&.name.presence || "everyone",
          group_id: Group::AUTO_GROUPS[:everyone],
        }
      end

      context[:permissions] = permissions
    end
  end
end
