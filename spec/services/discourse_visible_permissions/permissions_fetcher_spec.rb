# frozen_string_literal: true
require File.expand_path("../../../../../spec/rails_helper", __dir__)

describe DiscourseVisiblePermissions::PermissionsFetcher do
  fab!(:category)
  fab!(:group)
  fab!(:user_1, :user)
  fab!(:user_2, :user)

  before do
    group.add(user_1)
    group.add(user_2)
    # Wichtig: Der Fetcher basiert auf CategoryGroup
    CategoryGroup.create!(category: category, group: group, permission_type: 1)

    # user_1 beobachtet aktiv (Level 3)
    CategoryUser.create!(user: user_1, category: category, notification_level: 3)
    # user_2 hat keinen Eintrag -> nutzt Standard (Regular = 1)
  end

  it "calculates correct notification level counts per group and total" do
    result = described_class.call(category: category, guardian: Guardian.new(user_1))

    # 1. Test der Gruppen-Summen
    group_data = result.permissions.find { |g| g[:group_id] == group.id }
    expect(group_data[:notification_levels][3]).to eq(1) # user_1
    expect(group_data[:notification_levels][1]).to eq(1) # user_2 (default)

    # 2. Test der Gesamt-Summen
    total_counts = result.category_notification_totals
    expect(total_counts[3]).to eq(1) # user_1
    # Note: regular count might be higher if there are other real users in the test env
    expect(total_counts[1]).to be >= 1 # user_2
  end
end
