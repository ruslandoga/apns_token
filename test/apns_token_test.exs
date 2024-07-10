defmodule APNSTokenTest do
  use ExUnit.Case, async: true
  alias JOSE.JWT

  test "it works" do
    cache = :ets.new(:apns_jwt_cache, [:public])

    jwk =
      JOSE.JWK.from_pem("""
      -----BEGIN PRIVATE KEY-----
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgEbVzfPnZPxfAyxqE
      ZV05laAoJAl+/6Xt2O4mOB611sOhRANCAASgFTKjwJAAU95g++/vzKWHkzAVmNMI
      tB5vTjZOOIwnEb70MsWZFIyUFD1P9Gwstz4+akHX7vI8BH6hHmBmfeQl
      -----END PRIVATE KEY-----
      """)

    key_id = "ABC123DEFG"
    team_id = "DEF123GHIJ"

    now = System.system_time(:second)
    token = APNSToken.generate(jwk: jwk, kid: key_id, iss: team_id, cache: cache, now: now)

    assert %JWT{
             fields: %{
               "aud" => "appel",
               "exp" => exp,
               "iat" => ^now,
               "iss" => ^team_id,
               "jti" => _jti,
               "nbf" => ^now
             }
           } = JWT.peek(token)

    assert exp > now

    assert token == APNSToken.generate(jwk: jwk, kid: key_id, iss: team_id, cache: cache)
    refute token == APNSToken.generate(jwk: jwk, kid: key_id, iss: team_id, now: now + 1)
  end

  test "doesn't leak secrets" do
    jwk =
      JOSE.JWK.from_pem("""
      -----BEGIN PRIVATE KEY-----
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgEbVzfPnZPxfAyxqE
      ZV05laAoJAl+/6Xt2O4mOB611sOhRANCAASgFTKjwJAAU95g++/vzKWHkzAVmNMI
      tB5vTjZOOIwnEb70MsWZFIyUFD1P9Gwstz4+akHX7vI8BH6hHmBmfeQl
      -----END PRIVATE KEY-----
      """)

    key_id = "ABC123DEFG"
    team_id = "DEF123GHIJ"

    error =
      try do
        APNSToken.generate(jwk: jwk, kid: key_id, iss: team_id, cache: :no_such_table)
      rescue
        e ->
          Exception.format(:error, e, __STACKTRACE__)
      end

    refute error =~ key_id
  end
end
