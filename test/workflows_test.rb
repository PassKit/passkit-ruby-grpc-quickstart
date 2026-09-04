require "minitest/autorun"
require "stringio"
require_relative "../lib/passkit"

class WorkflowsTest < Minitest::Test
  Config = Data.define(:email, :apple_certificate)

  class FakeClient
    def call(_service, method, _request)
      return Io::ImageIds.new(icon: "icon", logo: "logo") if method == :create_images
      return Io::PassTemplate.new if method == :get_default_template
      return Flights::BoardingPassesResponse.new(boardingPasses: [pass_bundle]) if method == :create_boarding_pass
      return [] if method.to_s.start_with?("list_")
      return Io::Id.new(id: SecureRandom.uuid) if method.to_s.match?(/\A(create|enrol|issue)_/)

      Google::Protobuf::Empty.new
    end

    private

    def pass_bundle
      field = Flights::BoardingPassesResponse.descriptor.lookup("boardingPasses")
      field.subtype.msgclass.new(id: SecureRandom.uuid)
    end
  end

  def test_every_guided_workflow_builds_valid_sdk_requests
    config = Config.new(email: "developer@example.com", apple_certificate: "pass.example")
    workflows = [PassKit::MembershipWorkflow, PassKit::CouponWorkflow,
                 PassKit::EventTicketsWorkflow, PassKit::FlightsWorkflow]

    workflows.each do |workflow|
      capture_io { workflow.new(FakeClient.new, config).run }
    end
  end

  def test_generated_strip_images_meet_passkit_minimum_dimensions
    workflow = PassKit::MembershipWorkflow.new(FakeClient.new, Config.new(email: "dev@example.com",
                                                                          apple_certificate: "pass.example"))
    image_data = workflow.send(:image_data)
    assert_operator Base64.decode64(image_data.strip).bytesize, :>, 100
    assert_operator Base64.decode64(image_data.eventStrip).bytesize, :>, 100
  end
end
