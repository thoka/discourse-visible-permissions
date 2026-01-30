# frozen_string_literal: true

require File.expand_path("../../../../spec/rails_helper", __dir__)

RSpec.describe PrettyText do
  before { enable_current_plugin }

  it "renders visible-rights bbcode with data attributes" do
    cooked = PrettyText.cook("[visible-rights category=5]")

    expect(cooked).to match_html(
      "<p><span class=\"discourse-visible-rights\" data-category=\"5\"></span></p>",
    )
  end
end
