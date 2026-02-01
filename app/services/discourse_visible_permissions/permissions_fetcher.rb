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

      # 2. Cache expensive calculations per category
      # Invalidate if category or its groups/notifications change
      cache_key = "visible-permissions:cat-data:#{category.id}:#{category.updated_at.to_i}"
      ttl = SiteSetting.discourse_visible_permissions_cache_ttl_minutes

      fetch_data =
        proc do
          # Fetch data for all potentially relevant groups
          groups = Group.where(id: all_group_ids).to_a

          # Calculate totals for the entire category
          category_notification_totals = calculate_category_notification_totals(category)

          # Calculate levels for each group efficiently
          group_notification_counts =
            calculate_group_notification_counts(all_group_ids, category.id)

          group_data =
            groups.map do |group|
              notification_default =
                group.group_category_notification_defaults.find do |nd|
                  nd.category_id == category.id
                end
              category_group = group.category_groups.find { |cg| cg.category_id == category.id }

              {
                group_id: group.id,
                group_name: group.name,
                group_full_name: group.full_name,
                public_admission: group.public_admission,
                allow_membership_requests: group.allow_membership_requests,
                permission_type:
                  category_group&.permission_type || CategoryGroup.permission_types[:readonly],
                notification_level: notification_default&.notification_level,
                notification_levels:
                  if group.id == Group::AUTO_GROUPS[:everyone]
                    category_notification_totals
                  else
                    group_notification_counts[group.id]
                  end,
              }
            end

          { group_data: group_data, category_notification_totals: category_notification_totals }
        end

      cached_data =
        if ttl > 0
          Discourse.cache.fetch(cache_key, expires_in: ttl.minutes, &fetch_data)
        else
          fetch_data.call
        end

      # 3. Filter groups visible to current user and augment with user-specific flags
      visible_groups =
        Group.visible_groups(user, nil, include_everyone: true).where(id: all_group_ids).to_a
      visible_group_ids = visible_groups.map(&:id)

      permissions =
        cached_data[:group_data]
          .select { |gd| visible_group_ids.include?(gd[:group_id]) }
          .map do |gd|
            is_member = user && user.group_ids.include?(gd[:group_id])
            group_obj = visible_groups.find { |g| g.id == gd[:group_id] }

            {
              permission_type: gd[:permission_type],
              permission: CategoryGroup.permission_types.key(gd[:permission_type]),
              group_name: gd[:group_name],
              group_display_name: localized_group_name(gd[:group_name], gd[:group_full_name]),
              group_id: gd[:group_id],
              can_join: user && gd[:public_admission] && !is_member,
              can_request:
                user && gd[:allow_membership_requests] && !is_member &&
                  !GroupRequest.where(group_id: gd[:group_id], user: user).exists?,
              is_member: is_member,
              group_url: guardian.can_see?(group_obj) ? "/g/#{gd[:group_name]}" : nil,
              notification_level: gd[:notification_level],
              notification_levels: gd[:notification_levels],
            }
          end

      # 4. Handle 'everyone' group if it's missing (e.g. category not read_restricted)
      if !category.read_restricted &&
           !permissions.any? { |p| p[:group_id] == Group::AUTO_GROUPS[:everyone] }
        everyone_group = Group[:everyone]
        permissions.unshift(
          {
            permission_type: CategoryGroup.permission_types[:create_post],
            permission: "create_post",
            group_name: "everyone",
            group_display_name: localized_group_name("everyone", everyone_group&.full_name),
            group_id: Group::AUTO_GROUPS[:everyone],
            can_join: false,
            can_request: false,
            is_member: true,
            group_url: "/g/everyone",
            notification_level: nil,
            notification_levels: cached_data[:category_notification_totals],
          },
        )
      end

      permissions.sort_by! { |p| [p[:permission_type], p[:group_display_name] || ""] }

      context[:permissions] = permissions
      context[:category_notification_totals] = cached_data[:category_notification_totals]
    end

    def calculate_category_notification_totals(category)
      # Combined query to find the highest notification level for each user in this category
      sql = <<~SQL
        SELECT notification_level, COUNT(*) as count
        FROM (
          SELECT user_id, MAX(notification_level) as notification_level
          FROM (
            SELECT user_id, notification_level FROM category_users WHERE category_id = :category_id
            UNION ALL
            SELECT gu.user_id, gd.notification_level
            FROM group_category_notification_defaults gd
            JOIN group_users gu ON gu.group_id = gd.group_id
            WHERE gd.category_id = :category_id
          ) AS all_levels
          GROUP BY user_id
        ) AS max_levels
        GROUP BY notification_level
      SQL

      counts = Hash.new(0)
      DB
        .query(sql, category_id: category.id)
        .each { |row| counts[row.notification_level.to_i] = row.count.to_i }

      # Add regular users who don't have an override or default
      # Total real users minus those with any special level
      total_special_users = counts.values.sum
      total_real_users = User.real.count
      counts[NotificationLevels.all[:regular]] += [0, total_real_users - total_special_users].max

      counts
    end

    def calculate_group_notification_counts(group_ids, category_id)
      return {} if group_ids.blank?
      default_level = NotificationLevels.all[:regular]

      sql = <<~SQL
        SELECT gu.group_id, 
               COALESCE(cu.notification_level, gnd.notification_level, :default_level) as final_notification_level, 
               COUNT(*) as count
        FROM group_users gu
        LEFT JOIN group_category_notification_defaults gnd ON gnd.group_id = gu.group_id AND gnd.category_id = :category_id
        LEFT JOIN category_users cu ON cu.user_id = gu.user_id AND cu.category_id = :category_id
        WHERE gu.group_id IN (:group_ids)
        GROUP BY gu.group_id, final_notification_level
      SQL

      results = Hash.new { |h, k| h[k] = Hash.new(0) }
      DB
        .query(sql, group_ids: group_ids, category_id: category_id, default_level: default_level)
        .each do |row|
          results[row.group_id.to_i][row.final_notification_level.to_i] = row.count.to_i
        end
      results
    end

    def localized_group_name(name, full_name)
      return full_name if full_name.present?

      I18n.t(
        "discourse_visible_permissions.#{name}",
        default: ["groups.default_names.#{name}".to_sym, name.humanize],
      )
    end
  end
end
