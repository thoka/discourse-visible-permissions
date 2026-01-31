# frozen_string_literal: true

module DiscourseVisiblePermissions
  class PermissionsFetcher
    include Service::Base

    step :build_permissions

    private

    def build_permissions(category:, guardian:)
      user = guardian.user
      permissions =
        category
          .category_groups
          .joins(:group)
          .includes(:group)
          .merge(Group.visible_groups(user, "groups.name ASC", include_everyone: true))
          .map do |category_group|
            group = category_group.group
            is_member = user && user.group_ids.include?(group.id)

            {
              permission_type: category_group.permission_type,
              permission: CategoryGroup.permission_types.key(category_group.permission_type),
              group_name: group.name,
              group_display_name: group_display_name(group),
              group_id: category_group.group_id,
              can_join: user && group.public_admission && !is_member,
              can_request:
                user && group.allow_membership_requests && !is_member &&
                  !GroupRequest.where(group: group, user: user).exists?,
              is_member: is_member,
              group_url: guardian.can_see?(group) ? "/g/#{group.name}" : nil,
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
            can_join: false,
            can_request: false,
            is_member: true,
            group_url: "/g/everyone",
          },
        )
      end

      context[:permissions] = permissions
    end

    def group_display_name(group)
      return nil if group.nil?
      return group.full_name if group.full_name.present?

      I18n.t(
        "discourse_visible_permissions.#{group.name}",
        default: [
          "groups.default_names.#{group.name}".to_sym,
          group.name.humanize,
        ],
      )
    end
  end
end
