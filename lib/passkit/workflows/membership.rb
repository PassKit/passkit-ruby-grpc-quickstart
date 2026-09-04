require_relative "../workflow"

module PassKit
  class MembershipWorkflow < Workflow
    def execute
      template_id = create_template(:MEMBERSHIP, "Ruby Quickstart Membership")
      premium_template_id = create_template(:MEMBERSHIP, "Ruby Quickstart Premium Membership")
      program_id = id(rpc(:membership, :create_program, Members::Program.new(
                                                          name: "Ruby Quickstart #{SecureRandom.hex(3)}",
                                                          status: %i[PROJECT_DRAFT PROJECT_ACTIVE_FOR_OBJECT_CREATION]
                                                        )))
      remember("program", program_id) { |value| rpc(:membership, :delete_program, Io::Id.new(id: value)) }
      tier_id = id(rpc(:membership, :create_tier, Members::Tier.new(
                                                    id: "standard", name: "Standard", tierIndex: 1, programId: program_id,
                                                    passTemplateId: template_id, timezone: "Europe/London"
                                                  )))
      member_id = id(rpc(:membership, :enrol_member, Members::Member.new(
                                                       programId: program_id, tierId: tier_id, person: person("Ruby Member"), points: 100
                                                     )))
      remember("member", member_id) do |value|
        rpc(:membership, :delete_member, Members::Member.new(id: value, programId: program_id, tierId: tier_id))
      end
      premium_tier_id = id(rpc(:membership, :create_tier, Members::Tier.new(
                                                            id: "premium", name: "Premium", tierIndex: 2,
                                                            programId: program_id, passTemplateId: premium_template_id,
                                                            timezone: "Europe/London"
                                                          )))
      premium_member_id = id(rpc(:membership, :enrol_member, Members::Member.new(
                                                               programId: program_id, tierId: premium_tier_id,
                                                               person: person("Ruby Premium Member")
                                                             )))
      remember("premium member", premium_member_id) do |value|
        rpc(:membership, :delete_member,
            Members::Member.new(id: value, programId: program_id, tierId: premium_tier_id))
      end
      member_request = Members::MemberCheckInOutRequest.new(
        memberId: member_id, programId: program_id, externalEventId: SecureRandom.uuid,
        address: "Ruby Quickstart"
      )
      rpc(:membership, :check_in_member, member_request)
      member_request.externalEventId = SecureRandom.uuid
      rpc(:membership, :check_out_member, member_request)
      rpc(:membership, :get_member_record_by_id, Io::Id.new(id: member_id))
      rpc(:membership, :earn_points,
          Members::EarnBurnPointsRequest.new(id: member_id, programId: program_id, points: 10))
      rpc(:membership, :burn_points,
          Members::EarnBurnPointsRequest.new(id: member_id, programId: program_id, points: 5))
      rpc(:membership, :update_member, Members::Member.new(
                                         id: member_id, programId: program_id, tierId: tier_id,
                                         person: person("Updated Ruby Member")
                                       ))
      rpc(:membership, :list_members, Members::ListRequest.new(programId: program_id)).to_a
      rpc(:membership, :count_members, Members::ListRequest.new(programId: program_id))
      rpc(:membership, :list_events_for_member, Io::Id.new(id: member_id)).to_a
      puts "Created membership pass: #{member_id}"
    end
  end
end
