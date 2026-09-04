require_relative "../workflow"

module PassKit
  class FlightsWorkflow < Workflow
    def execute
      template_id = create_template(:FLIGHT_PROTOCOL, "Ruby Quickstart Boarding Pass")
      code = ENV.fetch("PASSKIT_FLIGHT_CARRIER_CODE", "YY")
      origin = ENV.fetch("PASSKIT_FLIGHT_ORIGIN", "YY4")
      destination = ENV.fetch("PASSKIT_FLIGHT_DESTINATION", "ADP")
      create_once(:carrier, code) do
        rpc(:flights, :create_carrier, Flights::Carrier.new(
                                         iataCarrierCode: code, airlineName: "Ruby Quickstart Airline",
                                         passTypeIdentifier: @config.apple_certificate
                                       ))
        remember("carrier", code) { |value| rpc(:flights, :delete_carrier, Flights::CarrierCode.new(carrierCode: value)) }
      end
      create_port(origin, "Quickstart Origin", "GB", "Europe/London")
      create_port(destination, "Quickstart Destination", "HK", "Asia/Hong_Kong")
      date = Time.now.utc + (7 * 86_400)
      passkit_date = Io::Date.new(year: date.year, month: date.month, day: date.day)
      number = rand(100..999).to_s
      flight = Flights::Flight.new(
        carrierCode: code, flightNumber: number, boardingPoint: origin, deplaningPoint: destination,
        departureDate: passkit_date, passTemplateId: template_id,
        scheduledDepartureTime: Io::LocalDateTime.new(dateTime: "#{date.strftime('%F')}T13:00:00"),
        scheduledArrivalTime: Io::LocalDateTime.new(dateTime: "#{date.strftime('%F')}T21:00:00")
      )
      rpc(:flights, :create_flight, flight)
      remember("flight", true) do
        rpc(:flights, :delete_flight, Flights::FlightRequest.new(
                                        carrierCode: code, flightNumber: number, boardingPoint: origin,
                                        deplaningPoint: destination, departureDate: passkit_date
                                      ))
      end
      times = Flights::FlightTimes.new(
        scheduledDepartureTime: Io::Time.new(hour: 13), boardingTime: Io::Time.new(hour: 12, minute: 15),
        gateClosingTime: Io::Time.new(hour: 12, minute: 30), scheduledArrivalTime: Io::Time.new(hour: 21)
      )
      schedule = Flights::FlightSchedule.new(
        monday: times, tuesday: times, wednesday: times, thursday: times,
        friday: times, saturday: times, sunday: times
      )
      designator = Flights::FlightDesignator.new(
        carrierCode: code, flightNumber: number, revision: 1, active: true,
        origin: origin, destination: destination, passTemplateId: template_id, schedule: schedule
      )
      rpc(:flights, :create_flight_designator, designator)
      remember("flight designator", true) do
        rpc(:flights, :delete_flight_designator,
            Flights::FlightDesignatorRequest.new(carrierCode: code, flightNumber: number, revision: 1))
      end
      rpc(:flights, :get_flight, Flights::FlightRequest.new(
                                   carrierCode: code, flightNumber: number, boardingPoint: origin,
                                   deplaningPoint: destination, departureDate: passkit_date
                                 ))
      rpc(:flights, :get_flight_designator,
          Flights::FlightDesignatorRequest.new(carrierCode: code, flightNumber: number, revision: 1))
      response = rpc(:flights, :create_boarding_pass, Flights::BoardingPassRecord.new(
                                                        operatingCarrierPNR: SecureRandom.alphanumeric(6).upcase, carrierCode: code, flightNumber: number,
                                                        boardingPoint: origin, deplaningPoint: destination, departureDate: passkit_date,
                                                        passenger: Flights::Passenger.new(passengerDetails: person("Ruby Flight Passenger")),
                                                        seatNumber: "12A", sequenceNumber: 123, class: "Economy"
                                                      ))
      response.boardingPasses.each do |pass|
        request = Flights::BoardingPassRecordRequest.new(passId: Io::Id.new(id: pass.id))
        rpc(:flights, :get_boarding_pass_record, request)
        remember("boarding pass", pass.id) do |value|
          request = Flights::BoardingPassRecordRequest.new(passId: Io::Id.new(id: value))
          rpc(:flights, :delete_boarding_pass, request)
        end
      end
      puts "Created boarding pass: #{response.to_h}"
    end

    def create_port(code, name, country, timezone)
      create_once(:airport, code) do
        rpc(:flights, :create_port, Flights::Port.new(
                                      iataAirportCode: code, airportName: name, cityName: name,
                                      countryCode: country, timezone: timezone
                                    ))
        remember("airport #{code}", code) do |value|
          rpc(:flights, :delete_port, Flights::AirportCode.new(airportCode: value))
        end
      end
    end

    def create_once(type, code)
      yield
    rescue GRPC::AlreadyExists
      puts "#{type.to_s.capitalize} #{code} already exists; reusing it."
    end
  end
end
