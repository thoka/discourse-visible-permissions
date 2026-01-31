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
    expect(page).to have_css(".discourse-visible-permissions-table", wait: 5)
    expect(page).to have_css(".discourse-visible-permissions-title", wait: 5)

    expect(page).to have_content("Permissions in area \"#{category.name}\"")

    within ".discourse-visible-permissions-table" do
      expect(page).to have_content(group.full_name.presence || group.name)
    end
  end

  it "renders the current category permissions when the BBCode is used without a category ID" do
    topic = Fabricate(:topic, category: category)
    post = Fabricate(:post, topic: topic, raw: "[show-permissions]")

    visit post.url

    expect(page).to have_css(".discourse-visible-permissions-table", wait: 5)

    within ".discourse-visible-permissions-table" do
      expect(page).to have_content(group.name)
    end
  end

  it "shows an error if the category is not found or inaccessible" do
    private_group = Fabricate(:group)
    private_category = Fabricate(:private_category, group: private_group) # user not in group
    post = Fabricate(:post, raw: "[show-permissions category=#{private_category.id}]")

    visit post.url

    expect(page).to have_content(I18n.t("js.discourse_visible_permissions.load_error"), wait: 5)
  end

  it "renders localized group names for automatic groups in German" do
    user.update!(locale: "de")
    category.set_permissions(:admins => :full, group.name => :readonly)
    category.save!
    category.update!(read_restricted: false)

    post = Fabricate(:post, raw: "[show-permissions category=#{category.id}]")

    visit post.url

    expect(page).to have_css(".discourse-visible-permissions-table", wait: 5)

    within ".discourse-visible-permissions-table" do
      expect(page).to have_content("Administratoren")
      expect(page).to have_content("jeder")

      # Check for tooltips (title attributes)
      expect(page).to have_css(".cell[title='#{I18n.t("js.category.permissions.see", locale: :de)}']")
      expect(page).to have_css(".cell[title='#{I18n.t("js.category.permissions.reply", locale: :de)}']")
      expect(page).to have_css(".cell[title='#{I18n.t("js.category.permissions.create", locale: :de)}']")
    end
  end
end
