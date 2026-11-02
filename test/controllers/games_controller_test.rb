# typed: true
# frozen_string_literal: true

require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "visitors without a name see only the name entry screen" do
    get root_path
    assert_response :success
    assert_select "#screen-username.active .username-form input[name=display_name][maxlength='20']"
    assert_select "#screen-lobby", count: 0
    assert_select "meta[name=current-user-id]", count: 0
  end

  test "the page loads the game client through the import map" do
    get root_path
    assert_select "script[type=importmap]", text: /"game_app"/
  end
end
