# frozen_string_literal: true
require File.expand_path("../../../../../spec/rails_helper", __dir__)

describe BasicCategorySerializer do
  fab!(:category) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user, trust_level: 1) }
  fab!(:group) { Fabricate(:group) }
  let(:guardian) { Guardian.new(user) }

  before do
    SiteSetting.discourse_visible_permissions_enabled = true
    SiteSetting.discourse_visible_permissions_min_trust_level = 1
  end

  it "includes visible_permissions when enabled" do
    serializer = BasicCategorySerializer.new(category, scope: guardian, root: false)
    json = serializer.as_json
    expect(json[:visible_permissions]).to be_present
    expect(json[:visible_permissions][:category_id]).to eq(category.id)
  end

  it "excludes visible_permissions when trust level is too low" do
    SiteSetting.discourse_visible_permissions_min_trust_level = 4
    serializer = BasicCategorySerializer.new(category, scope: guardian, root: false)
    json = serializer.as_json
    expect(json[:visible_permissions]).to be_nil
  end

  it "excludes visible_permissions when disabled" do
    SiteSetting.discourse_visible_permissions_enabled = false
    serializer = BasicCategorySerializer.new(category, scope: guardian, root: false)
    json = serializer.as_json
    expect(json[:visible_permissions]).to be_nil
  end
end
