require "minitest/autorun"
require "openssl"
require_relative "../lib/passkit/client"

class ClientCredentialsTest < Minitest::Test
  def test_normalizes_legacy_ec_private_keys_to_pkcs8
    key = OpenSSL::PKey::EC.generate("prime256v1")
    normalized = PassKit::Client.allocate.send(:normalize_private_key, key.to_pem)

    assert normalized.start_with?("-----BEGIN PRIVATE KEY-----")
    assert OpenSSL::PKey.read(normalized).private?
  end

  def test_rejects_an_encrypted_key_without_a_password
    key = OpenSSL::PKey::EC.generate("prime256v1")
    encrypted = key.export(OpenSSL::Cipher.new("aes-256-cbc"), "secret")

    error = assert_raises(ArgumentError) do
      PassKit::Client.allocate.send(:normalize_private_key, encrypted)
    end
    assert_match(/PASSKIT_KEY_PASSWORD/, error.message)
  end
end
