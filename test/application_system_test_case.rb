# typed: false
# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # CHROMEDRIVER_PATH / CHROME_BINARY let machines that block Selenium Manager's
  # downloaded driver point at an allowed one.
  Selenium::WebDriver::Chrome::Service.driver_path = ENV["CHROMEDRIVER_PATH"] if ENV["CHROMEDRIVER_PATH"]

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
    options.binary = ENV["CHROME_BINARY"] if ENV["CHROME_BINARY"]
  end

  def pick_name(name)
    visit root_path
    fill_in "display_name", with: name
    click_on "Play"
    assert_text "Playing as #{name}"
  end
end
