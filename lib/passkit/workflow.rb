require "base64"
require "securerandom"
require "zlib"
require "google/protobuf/timestamp_pb"

module PassKit
  class Workflow
    def initialize(client, config)
      @client = client
      @config = config
      @cleanup = []
      @image_cleanup_ids = {}
    end

    def run
      puts "Running #{self.class.name.split('::').last} quickstart..."
      execute
    ensure
      cleanup
    end

    private

    def rpc(service, method, request) = @client.call(service, method, request)
    def id(value) = value.respond_to?(:id) ? value.id : value.to_s

    def remember(label, value, &block)
      @cleanup.unshift([label, value, block]) unless value.to_s.empty?
      value
    end

    def cleanup
      puts "Cleaning up generated resources..."
      @cleanup.each do |label, value, action|
        action.call(value)
        puts "Deleted #{label}."
      rescue GRPC::BadStatus => e
        warn "Could not delete #{label}: #{e.details}"
      end
    end

    def create_template(protocol, name)
      image_ids = rpc(:images, :create_images, Io::CreateImageInput.new(
                                                 name: "#{name}-#{SecureRandom.hex(4)}", imageData: image_data
                                               ))
      image_ids.to_h.each do |key, value|
        next if value.to_s.empty? || @image_cleanup_ids[value]

        @image_cleanup_ids[value] = true
        remember("#{key} image", value) { |image_id| rpc(:images, :delete_image, Io::Id.new(id: image_id)) }
      end
      template = rpc(:templates, :get_default_template, Io::DefaultTemplateRequest.new(protocol:, revision: 1))
      template.name = name
      template.description = "Created by the PassKit Ruby quickstart"
      template.timezone = "Europe/London"
      template.imageIds = image_ids
      template_id = id(rpc(:templates, :create_template, template))
      remember("template", template_id) { |value| rpc(:templates, :delete_template, Io::Id.new(id: value)) }
    end

    def image_data
      Io::ImageData.new(icon: png(114, 114), logo: png(660, 660), appleLogo: png(660, 660),
                        hero: png(1032, 336), strip: png(1125, 432), eventStrip: png(1125, 432))
    end

    def png(width, height)
      raw = Array.new(height) { "\0#{[44, 110, 180, 255].pack('C4') * width}" }.join
      signature = "\x89PNG\r\n\x1a\n".b
      chunks = [["IHDR", [width, height, 8, 6, 0, 0, 0].pack("NNCCCCC")],
                ["IDAT", Zlib::Deflate.deflate(raw)], ["IEND", ""]]
      Base64.strict_encode64(signature + chunks.sum("") do |type, data|
        [data.bytesize, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
      end)
    end

    def person(name)
      Io::Person.new(displayName: name, emailAddress: @config.email)
    end
  end
end
