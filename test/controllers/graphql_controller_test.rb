# frozen_string_literal: true

require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  test "POST /graphql returns a valid response" do
    post "/graphql",
      params: { query: "{ testField }" },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["errors"]
    assert_equal "Hello World!", body.dig("data", "testField")
  end
end
