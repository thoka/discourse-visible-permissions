# frozen_string_literal: true

DiscourseVisibleRights::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseVisibleRights::Engine, at: "discourse-visible-rights" }
