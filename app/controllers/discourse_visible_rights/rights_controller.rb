# frozen_string_literal: true

module DiscourseVisibleRights
  class RightsController < ::ApplicationController
    requires_plugin DiscourseVisibleRights::PLUGIN_NAME
    requires_login

    def show
      raise Discourse::NotFound unless SiteSetting.discourse_visible_rights_enabled

      category = Category.find_by(id: params[:category_id])
      raise Discourse::NotFound if category.blank? || !guardian.can_see?(category)

      result = RightsFetcher.call(category: category, guardian: guardian)

      render json: { category_id: category.id, group_permissions: result.permissions }
    end
  end
end
