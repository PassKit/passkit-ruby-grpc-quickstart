require_relative "../workflow"

module PassKit
  class EventTicketsWorkflow < Workflow
    def execute
      template_id = create_template(:EVENT_TICKETING, "Ruby Quickstart Event Ticket")
      production_id = id(rpc(:event_tickets, :create_production, EventTickets::Production.new(
                                                                   name: "Ruby Event #{SecureRandom.hex(3)}", status: %i[
                                                                     PROJECT_DRAFT PROJECT_ACTIVE_FOR_OBJECT_CREATION
                                                                   ]
                                                                 )))
      remember("production", production_id) do |value|
        rpc(:event_tickets, :delete_production, EventTickets::Production.new(id: value))
      end
      venue_id = id(rpc(:event_tickets, :create_venue, EventTickets::Venue.new(
                                                         name: "Ruby Quickstart Venue", address: "123 Example Street", timezone: "Europe/London"
                                                       )))
      remember("venue", venue_id) { |value| rpc(:event_tickets, :delete_venue, EventTickets::Venue.new(id: value)) }
      start = Google::Protobuf::Timestamp.new(seconds: (Time.now + (7 * 86_400)).to_i)
      finish = Google::Protobuf::Timestamp.new(seconds: (Time.now + (7 * 86_400) + 10_800).to_i)
      event_id = id(rpc(:event_tickets, :create_event, EventTickets::Event.new(
                                                         production: EventTickets::Production.new(id: production_id), venue: EventTickets::Venue.new(id: venue_id),
                                                         scheduledStartDate: start, endDate: finish
                                                       )))
      remember("event", event_id) do |value|
        rpc(:event_tickets, :delete_event, EventTickets::Event.new(id: value))
      end
      ticket_type_id = id(rpc(:event_tickets, :create_ticket_type, EventTickets::TicketType.new(
                                                                     productionId: production_id, name: "General Admission", beforeRedeemPassTemplateId: template_id
                                                                   )))
      remember("ticket type", ticket_type_id) do |value|
        rpc(:event_tickets, :delete_ticket_type,
            EventTickets::TicketType.new(id: value, productionId: production_id))
      end
      ticket_number = SecureRandom.hex(4)
      order_number = SecureRandom.hex(4)
      ticket_id = id(rpc(:event_tickets, :issue_ticket, EventTickets::IssueTicketRequest.new(
                                                          eventId: event_id, ticketTypeId: ticket_type_id, ticketNumber: ticket_number,
                                                          orderNumber: order_number, person: person("Ruby Ticket Holder")
                                                        )))
      remember("ticket", ticket_id) do |value|
        rpc(:event_tickets, :delete_ticket, EventTickets::TicketId.new(ticketId: value))
      end
      rpc(:event_tickets, :get_ticket_by_id, Io::Id.new(id: ticket_id))
      rpc(:event_tickets, :get_ticket_by_ticket_number,
          EventTickets::TicketNumberRequest.new(productionId: production_id, ticketNumber: ticket_number))
      rpc(:event_tickets, :get_tickets_by_order_number,
          EventTickets::OrderNumberRequest.new(productionId: production_id, orderNumber: order_number))
      rpc(:event_tickets, :list_tickets,
          EventTickets::TicketListRequest.new(productionId: production_id, eventId: event_id)).to_a
      ticket_ref = EventTickets::TicketId.new(ticketId: ticket_id)
      rpc(:event_tickets, :validate_ticket,
          EventTickets::ValidateTicketRequest.new(ticket: ticket_ref, maxNumberOfValidations: 3))
      rpc(:event_tickets, :update_ticket,
          EventTickets::Ticket.new(id: ticket_id, person: person("Updated Ruby Ticket Holder")))
      rpc(:event_tickets, :redeem_ticket, EventTickets::RedeemTicketRequest.new(ticket: ticket_ref))
      puts "Created event ticket: #{ticket_id}"
    end
  end
end
