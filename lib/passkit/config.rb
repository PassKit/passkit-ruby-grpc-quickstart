require "dotenv/load"

module PassKit
  Config = Data.define(:certificate, :key, :key_password, :ca_chain, :host, :port, :pool_size, :email,
                       :apple_certificate) do
    def self.load(env = ENV)
      new(
        certificate: env.fetch("PASSKIT_CERTIFICATE", "certs/certificate.pem"),
        key: env.fetch("PASSKIT_KEY", "certs/key.pem"),
        key_password: env["PASSKIT_KEY_PASSWORD"],
        ca_chain: env.fetch("PASSKIT_CA_CHAIN", "certs/ca-chain.pem"),
        host: env.fetch("PASSKIT_GRPC_HOST", "grpc.pub1.passkit.io"),
        port: Integer(env.fetch("PASSKIT_GRPC_PORT", "443")),
        pool_size: Integer(env.fetch("PASSKIT_POOL_SIZE", "4")),
        email: env["PASSKIT_EMAIL"],
        apple_certificate: env["PASSKIT_APPLE_CERTIFICATE"]
      )
    rescue ArgumentError
      raise ArgumentError, "PASSKIT_GRPC_PORT and PASSKIT_POOL_SIZE must be whole numbers"
    end

    def validate!(workflow: nil)
      raise ArgumentError, "PASSKIT_POOL_SIZE must be at least 1" if pool_size < 1

      { "PASSKIT_CERTIFICATE" => certificate, "PASSKIT_KEY" => key,
        "PASSKIT_CA_CHAIN" => ca_chain }.each do |name, path|
        raise ArgumentError, "#{name} does not exist: #{path}" unless File.file?(path)
      end
      raise ArgumentError, "PASSKIT_EMAIL is required" if email.to_s.strip.empty?
      return self unless workflow == "flights" && apple_certificate.to_s.strip.empty?

      raise ArgumentError, "PASSKIT_APPLE_CERTIFICATE is required for flights"
    end

    def endpoint = "#{host}:#{port}"
  end
end
