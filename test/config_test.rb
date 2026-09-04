require "minitest/autorun"
require_relative "../lib/passkit/config"

class ConfigTest < Minitest::Test
  def test_defaults_and_endpoint
    config = PassKit::Config.load("PASSKIT_EMAIL" => "dev@example.com")
    assert_equal "grpc.pub1.passkit.io:443", config.endpoint
    assert_equal 4, config.pool_size
  end

  def test_rejects_invalid_pool_size
    config = PassKit::Config.load("PASSKIT_POOL_SIZE" => "0", "PASSKIT_EMAIL" => "dev@example.com")
    error = assert_raises(ArgumentError) { config.validate! }
    assert_match(/at least 1/, error.message)
  end
end
