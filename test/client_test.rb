require "minitest/autorun"
require_relative "../lib/passkit/client"

class ClientTest < Minitest::Test
  def test_all_quickstart_services_are_available
    expected = %i[
      analytics certificates coupons distribution event_tickets flights images integrations
      membership messages raw scheduler templates users
    ]
    assert_equal expected, PassKit::Client::SERVICES.keys.sort
  end

  def test_core_workflow_methods_are_exposed
    assert_includes PassKit::Client::SERVICES[:membership].instance_methods(false), :create_program
    assert_includes PassKit::Client::SERVICES[:coupons].instance_methods(false), :create_coupon_campaign
    assert_includes PassKit::Client::SERVICES[:event_tickets].instance_methods(false), :issue_ticket
    assert_includes PassKit::Client::SERVICES[:flights].instance_methods(false), :create_boarding_pass
  end

  def test_exposes_the_complete_generated_sdk_surface
    count = PassKit::Client::SERVICES.sum do |_name, stub|
      stub.instance_methods(false).count { |method| !method.to_s.end_with?("_deprecated") }
    end
    assert_operator count, :>=, 200
  end
end
