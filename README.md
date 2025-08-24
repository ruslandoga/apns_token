# APNs Token

[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)](https://hexdocs.pm/apns_token)
[![Hex.pm badge](https://img.shields.io/badge/Package%20on%20hex.pm-informational)](https://hex.pm/packages/apns_token)

Tiny library to generate and cache [APNs](https://developer.apple.com/documentation/usernotifications) (Apple Push Notification service) [tokens.](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns)

Can be used with [Finch](https://github.com/sneako/finch) for a full-featured APNs client. Note however, that APNs doesn't support authentication tokens from multiple developer accounts over a single connection.

## Installation

```elixir
defp deps do
  [
    {:apns_token, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
Mix.install([:apns_token, :jason, :finch])

Finch.start_link(
  name: MyApp.Finch,
  pools: %{
    "api.development.push.apple.com" => [protocol: :http2],
    "api.push.apple.com" => [protocol: :http2]
  }
)

:ets.new(:apns_jwt_cache, [:named_table, :public, read_concurrency: true])

# NOTE: key, key_id, and team_id can be stored in app env on startup,
#       e.g. in your app's config/runtime.exs

# Auth Key from .p8 file from Apple
jwk =
  JOSE.JWK.from_pem("""
  -----BEGIN PRIVATE KEY-----
  MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgEbVzfPnZPxfAyxqE
  ZV05laAoJAl+/6Xt2O4mOB611sOhRANCAASgFTKjwJAAU95g++/vzKWHkzAVmNMI
  tB5vTjZOOIwnEb70MsWZFIyUFD1P9Gwstz4+akHX7vI8BH6hHmBmfeQl
  -----END PRIVATE KEY-----
  """)

# Key ID from developer account (Certificates, Identifiers & Profiles -> Keys)
key_id = "ABC123DEFG"
# Team ID from developer account (View Account -> Membership)
team_id = "DEF123GHIJ"

token = :apns_token.generate(jwk: jwk, kid: key_id, iss: team_id, cache: :apns_jwt_cache)

device_id = "11aa01229f15f0f0c52029d8cf8cd0aeaf2365fe4cebc4af26cd6d76b7919ef7"
topic = "com.sideshow.Apns2"

url = "https://api.development.push.apple.com/3/device/" <> device_id

headers = [
  {"authorization", "bearer " <> token},
  {"apns-topic", topic},
  {"apns-push-type", "alert"}
]

body = Jason.encode_to_iodata!(%{"aps" => %{"alert" => "Hello"}})
req = Finch.build(:post, url, headers, body)
Finch.request(req, MyApp.Finch)
```
