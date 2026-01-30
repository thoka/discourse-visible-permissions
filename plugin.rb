# frozen_string_literal: true

# name: discourse-visible-rights
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_visible_rights_enabled

module ::DiscourseVisibleRights
  PLUGIN_NAME = "discourse-visible-rights"
end

require_relative "lib/discourse_visible_rights/engine"

after_initialize do
  require_relative "app/controllers/discourse_visible_rights/rights_controller"
  require_relative "app/services/discourse_visible_rights/rights_fetcher"

  Discourse::Application.routes.prepend do
    get "/c/:category_id/visible-rights" => "discourse_visible_rights/rights#show",
        :constraints => {
          format: :json,
        }
  end
end
