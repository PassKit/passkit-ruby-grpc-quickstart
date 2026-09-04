require "grpc"
require "openssl"
require "io/member/a_rpc_services_pb"
require "io/single_use_coupons/a_rpc_services_pb"
require "io/event_tickets/a_rpc_services_pb"
require "io/flights/a_rpc_services_pb"
require "io/analytics/a_rpc_services_pb"
require "io/raw/a_rpc_services_pb"
require "io/scheduler/a_rpc_services_pb"
require "io/core/a_rpc_certificates_services_pb"
require "io/core/a_rpc_distribution_services_pb"
require "io/core/a_rpc_images_services_pb"
require "io/core/a_rpc_messages_services_pb"
require "io/core/a_rpc_templates_services_pb"
require "io/core/a_rpc_others_services_pb"

module PassKit
  class Client
    SERVICES = {
      membership: Members::Members::Stub,
      coupons: SingleUseCoupons::SingleUseCoupons::Stub,
      event_tickets: EventTickets::EventTickets::Stub,
      flights: Flights::Flights::Stub,
      analytics: Analytics::Analytics::Stub,
      raw: Raw::Raw::Stub,
      scheduler: Scheduler::Scheduler::Stub,
      certificates: Io::Certificates::Stub,
      distribution: Io::Distribution::Stub,
      images: Io::Images::Stub,
      messages: Io::Messages::Stub,
      templates: Io::Templates::Stub,
      users: Io::Users::Stub,
      integrations: Io::Integrations::Stub
    }.freeze

    attr_reader(*SERVICES.keys)

    def initialize(config)
      certificate = File.binread(config.certificate)
      private_key = normalize_private_key(File.binread(config.key), config.key_password)
      validate_key_pair!(certificate, private_key)
      credentials = GRPC::Core::ChannelCredentials.new(
        File.binread(config.ca_chain), private_key, certificate
      )
      SERVICES.each { |name, stub| instance_variable_set("@#{name}", stub.new(config.endpoint, credentials)) }
    end

    def call(service, method, request, **)
      public_send(service).public_send(method, request, **)
    end

    def methods_for(service)
      SERVICES.fetch(service.to_sym).instance_methods(false).sort
    end

    def operation_count
      SERVICES.sum { |name, _| methods_for(name).count { |method| !method.to_s.end_with?("_deprecated") } }
    end

    private

    def normalize_private_key(pem, password = nil)
      raise ArgumentError, "PASSKIT_KEY is encrypted; set PASSKIT_KEY_PASSWORD in .env" if pem.include?("ENCRYPTED") && password.to_s.empty?

      OpenSSL::PKey.read(pem, password).private_to_pem
    rescue OpenSSL::PKey::PKeyError => e
      raise ArgumentError, "PASSKIT_KEY is not a readable, unencrypted PEM private key: #{e.message}"
    end

    def validate_key_pair!(certificate_pem, private_key_pem)
      certificate = OpenSSL::X509::Certificate.new(certificate_pem)
      private_key = OpenSSL::PKey.read(private_key_pem)
      return if certificate.check_private_key(private_key)

      raise ArgumentError, "PASSKIT_CERTIFICATE and PASSKIT_KEY do not belong to the same credential"
    rescue OpenSSL::X509::CertificateError => e
      raise ArgumentError, "PASSKIT_CERTIFICATE is not a valid PEM certificate: #{e.message}"
    end
  end
end
