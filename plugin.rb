# frozen_string_literal: true

# name: discourse-visible-permissions
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_visible_permissions_enabled

register_svg_icon "square-check"
register_svg_icon "far-square"
register_svg_icon "far-eye"

module ::DiscourseVisiblePermissions
  PLUGIN_NAME = "discourse-visible-permissions"
end

require_relative "lib/discourse_visible_permissions/engine"

after_initialize do
  require_relative "app/controllers/discourse_visible_permissions/permissions_controller"
  require_relative "app/services/discourse_visible_permissions/permissions_fetcher"

  Discourse::Application.routes.prepend do
    get "/c/:category_id/permissions" => "discourse_visible_permissions/permissions#show",
        :constraints => {
          format: :json,
        }
  end
end
