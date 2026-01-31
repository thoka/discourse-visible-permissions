# frozen_string_literal: true

require File.expand_path("../../../../../spec/rails_helper", __dir__)

RSpec.describe DiscourseVisiblePermissions::PermissionsController do
  before { enable_current_plugin }

  fab!(:group)
  fab!(:category)
  fab!(:private_category) { Fabricate(:private_category, group: group) }
  fab!(:user)

  before do
    SiteSetting.discourse_visible_permissions_enabled = true
    category.set_permissions(group.name => :create_post)
    category.save!
  end

  it "requires login" do
    get "/c/#{category.id}/permissions", xhr: true
    expect(response.status).to eq(403)
  end

  it "returns group permissions for a visible category" do
    sign_in(user)
    group.add(user)

    get "/c/#{category.id}/permissions", xhr: true

    expect(response.status).to eq(200)
    json = response.parsed_body

    expect(json["category_id"]).to eq(category.id)
    expect(json["category_name"]).to eq(category.name)
    expect(json["group_permissions"]).to contain_exactly(
      {
        "permission_type" => CategoryGroup.permission_types[:create_post],
        "permission" => "create_post",
        "group_name" => group.name,
        "group_display_name" => group.full_name.presence || group.name,
        "group_id" => group.id,
      },
    )
  end

  it "returns 'everyone' permissions for a public category" do
    sign_in(user)
    category.set_permissions(admins: :full) # Restricted to admins
    category.save!
    category.update!(read_restricted: false) # But publicly visible

    get "/c/#{category.id}/permissions", xhr: true

    expect(response.status).to eq(200)
    json = response.parsed_body

    everyone_group = Group[:everyone]
    expect(json["group_permissions"]).to include(
      {
        "permission_type" => CategoryGroup.permission_types[:create_post],
        "permission" => "create_post",
        "group_name" => everyone_group.name,
        "group_display_name" => everyone_group.full_name.presence || everyone_group.name,
        "group_id" => everyone_group.id,
      },
    )
  end

  it "returns not found when category is not visible" do
    sign_in(user)

    get "/c/#{private_category.id}/permissions", xhr: true

    expect(response.status).to eq(404)
  end

  it "returns localized group names" do
    user.update!(locale: "de")
    sign_in(user)
    group.add(user)

    category.set_permissions(:admins => :full, group.name => :readonly)
    category.save!
    category.update!(read_restricted: false)

    get "/c/#{category.id}/permissions", xhr: true

    expect(response.status).to eq(200)
    json = response.parsed_body

    admin_perm = json["group_permissions"].find { |p| p["group_name"] == "admins" }
    expect(admin_perm["group_display_name"]).to eq("Administratoren")

    everyone_perm =
      json["group_permissions"].find { |p| p["group_id"] == Group::AUTO_GROUPS[:everyone] }
    expect(everyone_perm["group_display_name"]).to eq("jeder")
  end
end
