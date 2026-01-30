# frozen_string_literal: true

require File.expand_path("../../../../spec/rails_helper", __dir__)

RSpec.describe "Visible Permissions", type: :system do
  fab!(:admin)
  fab!(:category)
  fab!(:group)
  fab!(:user)

  before do
    SiteSetting.discourse_visible_permissions_enabled = true
    category.set_permissions(group.name => :create_post)
    category.save!
    group.add(user)
    sign_in(user)
  end

  it "renders category permissions when the BBCode is used in a post" do
    post = Fabricate(:post, raw: "[show-permissions category=#{category.id}]")

    visit post.url

    # Wait for the decorator to run and fetch data
    expect(page).to have_css(".discourse-visible-permissions-raw", wait: 5)

    within ".discourse-visible-permissions-raw" do
      expect(page).to have_content("\"group_name\": \"#{group.name}\"")
      expect(page).to have_content("\"permission\": \"create_post\"")
    end
  end

  it "renders the current category permissions when the BBCode is used without a category ID" do
    topic = Fabricate(:topic, category: category)
    post = Fabricate(:post, topic: topic, raw: "[show-permissions]")

    visit post.url

    expect(page).to have_css(".discourse-visible-permissions-raw", wait: 5)

    within ".discourse-visible-permissions-raw" do
      expect(page).to have_content("\"group_name\": \"#{group.name}\"")
    end
  end

  it "shows an error if the category is not found or inaccessible" do
    private_category = Fabricate(:private_category) # user not in group
    post = Fabricate(:post, raw: "[show-permissions category=#{private_category.id}]")

    visit post.url

    expect(page).to have_content(I18n.t("js.discourse_visible_permissions.load_error"), wait: 5)
  end
end
