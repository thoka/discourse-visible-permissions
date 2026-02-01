# frozen_string_literal: true

require File.expand_path("../../../../../spec/rails_helper", __dir__)

RSpec.describe DiscourseVisiblePermissions::PermissionsController do
  before { enable_current_plugin }

  fab!(:group)
  fab!(:category)
  fab!(:user)
  fab!(:user_in_group) { Fabricate(:user) }

  before do
    SiteSetting.discourse_visible_permissions_enabled = true
    user.update!(admin: true)
    group.add(user_in_group)
    sign_in(user)
  end

  describe "notifications" do
    it "returns the default notification level for a group" do
      GroupCategoryNotificationDefault.create!(
        group: group,
        category: category,
        notification_level: NotificationLevels.all[:watching]
      )

      get "/c/#{category.id}/permissions", xhr: true

      expect(response.status).to eq(200)
      json = response.parsed_body
      
      group_perm = json["group_permissions"].find { |p| p["group_id"] == group.id }
      expect(group_perm).to be_present
      expect(group_perm["notification_level"]).to eq(NotificationLevels.all[:watching])
    end

    it "includes a group that only has notification defaults but no specific category permissions" do
      # Set no specific category permissions for the group
      category.set_permissions(admins: :full) # only admins
      category.save!
      
      # Set a notification default for the group
      GroupCategoryNotificationDefault.create!(
        group: group,
        category: category,
        notification_level: NotificationLevels.all[:watching]
      )

      get "/c/#{category.id}/permissions", xhr: true

      expect(response.status).to eq(200)
      json = response.parsed_body
      
      group_ids = json["group_permissions"].map { |p| p["group_id"] }
      expect(group_ids).to include(group.id)
    end

    it "returns the correct notified_count for a group" do
      # Case: Group is watching, so all members are notified
      GroupCategoryNotificationDefault.create!(
        group: group,
        category: category,
        notification_level: NotificationLevels.all[:watching]
      )
      
      # Add another user to group
      another_user = Fabricate(:user)
      group.add(another_user)

      get "/c/#{category.id}/permissions", xhr: true

      json = response.parsed_body
      group_perm = json["group_permissions"].find { |p| p["group_id"] == group.id }
      
      # user_in_group and another_user are in the group.
      expect(group_perm["notification_levels"]["3"]).to eq(2) # Level 3 = Watching
    end

    it "adjusts notification levels based on individual user overrides" do
      GroupCategoryNotificationDefault.create!(
        group: group,
        category: category,
        notification_level: NotificationLevels.all[:watching]
      )

      # user_in_group mutes the category manually
      CategoryUser.create!(
        user: user_in_group,
        category: category,
        notification_level: NotificationLevels.all[:muted]
      )

      get "/c/#{category.id}/permissions", xhr: true

      json = response.parsed_body
      group_perm = json["group_permissions"].find { |p| p["group_id"] == group.id }
      
      # Group Watching(3) but User Muted(0)
      expect(group_perm["notification_levels"]["3"].to_i).to eq(0)
      expect(group_perm["notification_levels"]["0"].to_i).to eq(1)
    end
  end
end
