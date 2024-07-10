defmodule APNSToken do
  @moduledoc "Tiny APNs token generator"
  alias JOSE.{JWK, JWS, JWT}

  @doc """
  Returns a JWT token suitable for APNs.

  ## Options

    * `:jwk` - JWK from PEM-encoded token signing key downloaded from [developer.apple.com](https://developer.apple.com/account/resources/keys/list)
    * `:kid` - The 10-character Key ID you obtained from your developer account; see [Get a key identifier.](https://developer.apple.com/help/account/manage-keys/get-a-key-identifier)
    * `:iss` - The issuer key, the value for which is the 10-character Team ID you use for developing your company’s apps. Obtain this value from your developer account.
    * `:cache` - an ETS table name to be used as cache. For example: `:ets.new(:your_name, [:named_table, :public, read_concurrency: true])`

  Please see [Obtain an encryption key and key ID from Apple](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns#Obtain-an-encryption-key-and-key-ID-from-Apple) for more details.
  """
  def generate(options) do
    %JWK{} = jwk = Keyword.fetch!(options, :jwk)
    kid = Keyword.fetch!(options, :kid)
    iss = Keyword.fetch!(options, :iss)
    cache = Keyword.get(options, :cache)

    # "hidden" opts
    max_age = Keyword.get(options, :max_age) || jitter_max_age()
    now = Keyword.get(options, :now) || System.system_time(:second)

    generate(jwk, kid, iss, cache, now, max_age)
  rescue
    e -> reraise e, prune_args_from_stacktrace(__STACKTRACE__)
  end

  defp generate(jwk, kid, iss, cache, now, max_age) do
    lookup_token(kid, cache, now, max_age) || refresh_token(jwk, kid, iss, cache, now)
  end

  defp jitter_max_age do
    # somewhere between 50 and 59 minutes (in seconds)
    # this randomness allows us to somewhat avoid lookup/refresh races
    3000 + :rand.uniform(540)
  end

  defp lookup_token(kid, cache, now, max_age) do
    if cache do
      case :ets.lookup(cache, kid) do
        [{_kid, token}] -> if token_age(token, now) < max_age, do: token
        [] -> nil
      end
    end
  end

  defp token_age(token, now) do
    %JWT{fields: %{"iat" => iat}} = JWT.peek(token)
    now - iat
  end

  defp refresh_token(jwk, kid, iss, cache, now) do
    jws = JWS.from_map(%{"alg" => "ES256", "kid" => kid, "typ" => "JWT"})

    jti =
      Base.hex_encode32(
        <<
          System.system_time(:nanosecond)::64,
          :erlang.phash2({node(), self()}, 16_777_216)::24,
          :erlang.unique_integer()::32
        >>,
        case: :lower
      )

    jwt =
      JWT.sign(jwk, jws, %{
        # TODO
        "aud" => "appel",
        "iss" => iss,
        "nbf" => now,
        "iat" => now,
        "exp" => now + 3600,
        "jti" => jti
      })

    {_, token} = JWS.compact(jwt)

    if cache do
      :ets.insert(cache, {kid, token})
    end

    token
  end

  # Prunes the stacktrace to remove any argument trace.
  #
  # This is useful when working with functions that receives secrets
  # and we want to make sure those secrets do not leak on error messages.
  @spec prune_args_from_stacktrace(Exception.stacktrace()) :: Exception.stacktrace()
  defp prune_args_from_stacktrace(stacktrace)

  defp prune_args_from_stacktrace([{mod, fun, [_ | _] = args, info} | rest]) do
    [{mod, fun, length(args), info} | rest]
  end

  defp prune_args_from_stacktrace(stacktrace) when is_list(stacktrace) do
    stacktrace
  end
end
