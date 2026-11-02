# typed: true
# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "picking a name creates a user, remembers them, and opens the lobby" do
    assert_difference "User.count", 1 do
      post join_path, params: { display_name: "  Russell  " }
    end
    assert_redirected_to root_path
    assert_equal "Russell", User.last.display_name

    get root_path
    assert_select "meta[name=current-user-name][content=Russell]"
    assert_select "#screen-lobby"
    assert_select "#screen-username.active", count: 0
  end

  test "a blank name is rejected with a message" do
    assert_no_difference "User.count" do
      post join_path, params: { display_name: "  " }
    end
    follow_redirect!
    assert_select ".form-error", text: "Display name can't be blank"
  end

  test "names longer than 20 characters are rejected" do
    post join_path, params: { display_name: "x" * 21 }
    follow_redirect!
    assert_select ".form-error", text: /too long/
  end

  test "changing name forgets the current user" do
    post join_path, params: { display_name: "Russell" }
    delete logout_path
    get root_path
    assert_select "#screen-username.active"
  end
end
