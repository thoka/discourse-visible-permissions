# frozen_string_literal: true

module DiscourseVisiblePermissions
  class PermissionsFetcher
    include Service::Base

    step :build_permissions

    private

    def build_permissions(category:, guardian:)
      user = guardian.user

      # 1. Get all relevant group IDs
      permission_group_ids = category.category_groups.pluck(:group_id)
      notification_group_ids =
        GroupCategoryNotificationDefault.where(category: category).pluck(:group_id)
      all_group_ids = (permission_group_ids + notification_group_ids).uniq

      # 2. Fetch visible groups
      visible_groups =
        Group
          .visible_groups(user, "groups.name ASC", include_everyone: true)
          .where(id: all_group_ids)
          .includes(:category_groups, :group_category_notification_defaults)

      permissions =
        visible_groups.map do |group|
          is_member = user && user.group_ids.include?(group.id)
          category_group = group.category_groups.find { |cg| cg.category_id == category.id }
          notification_default =
            group.group_category_notification_defaults.find { |nd| nd.category_id == category.id }

          {
            permission_type:
              category_group&.permission_type || CategoryGroup.permission_types[:readonly],
            permission:
              CategoryGroup.permission_types.key(
                category_group&.permission_type || CategoryGroup.permission_types[:readonly],
              ),
            group_name: group.name,
            group_display_name: group_display_name(group),
            group_id: group.id,
            can_join: user && group.public_admission && !is_member,
            can_request:
              user && group.allow_membership_requests && !is_member &&
                !GroupRequest.where(group: group, user: user).exists?,
            is_member: is_member,
            group_url: guardian.can_see?(group) ? "/g/#{group.name}" : nil,
            notification_level: notification_default&.notification_level,
            notification_levels:
              calculate_notification_levels(group, category, notification_default),
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
            notification_level: nil,
            notified_count: 0,
            notification_levels: {
            },
          },
        )
      end

      permissions.sort_by! { |p| [p[:permission_type], p[:group_display_name] || ""] }

      context[:permissions] = permissions
      context[:category_notification_totals] = calculate_category_notification_totals(category)
    end

    def calculate_category_notification_totals(category)
      user_levels = {}

      # 1. CategoryUser overrides
      CategoryUser
        .where(category: category)
        .pluck(:user_id, :notification_level)
        .each { |uid, lvl| user_levels[uid] = lvl }

      # 2. Group defaults
      # Sort by level DESC so we pick the highest level for users in multiple groups
      GroupCategoryNotificationDefault
        .where(category: category)
        .order(notification_level: :desc)
        .each do |gd|
          gd.group.users.pluck(:id).each { |uid| user_levels[uid] ||= gd.notification_level }
        end

      counts = Hash.new(0)
      user_levels.each_value { |lvl| counts[lvl] += 1 }
      counts
    end

    def calculate_notification_levels(group, category, notification_default)
      default_level = notification_default&.notification_level || NotificationLevels.all[:regular]

      # Users in group
      group_user_ids = group.users.select(:id)

      # Get all overrides for these users in this category
      overrides =
        CategoryUser
          .where(category: category, user_id: group_user_ids)
          .pluck(:user_id, :notification_level)
          .to_h

      counts = Hash.new(0)

      # We need to apply default_level to users without an override
      group.users.pluck(:id).each { |user_id| counts[overrides[user_id] || default_level] += 1 }

      counts
    end

    def group_display_name(group)
      return nil if group.nil?
      return group.full_name if group.full_name.present?

      I18n.t(
        "discourse_visible_permissions.#{group.name}",
        default: ["groups.default_names.#{group.name}".to_sym, group.name.humanize],
      )
    end
  end
end
