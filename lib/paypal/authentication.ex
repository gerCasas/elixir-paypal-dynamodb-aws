defmodule Paypal.Authentication do
  use Timex
  require Logger

  def start_link() do
    Agent.start_link(fn -> %{token: nil, expires_in: -1} end, name: :token)
  end

  def token do
    if is_expired() do
      request_token()
    end
    Agent.get(:token, &(&1))
  end

  defp is_expired do
    %{token: _, expires_in: expires } = Agent.get(:token, &(&1))
    :os.timestamp |> Duration.from_erl |> Duration.to_seconds > expires
  end

  defp get_env(key), do: Application.get_env(:pay, :paypal)[key]

  defp request_token() do
    Logger.debug "Var client_id: #{get_env(:client_id)}"
    Logger.debug "Var secret: #{get_env(:secret)}"

    hackney = [basic_auth: {get_env(:client_id), get_env(:secret)}]
    HTTPoison.post(Paypal.Config.url <> "/oauth2/token", "grant_type=client_credentials", basic_headers(), [ hackney: hackney ])
#    HTTPoison.post("https://api.sandbox.paypal.com/v1/oauth2/token", "grant_type=client_credentials", basic_headers, [ hackney: hackney ])
    |> Paypal.Config.parse_response
    |> parse_token
    |> update_token

#    %{token: token, expires_in: expires } = Agent.get(:token, &(&1))
#    Logger.debug "token #{token}"
#    Logger.debug "expires #{expires}"
#    Logger.debug "access_token: #{access_token}"
#    Logger.debug "expires_in: #{expires_in}"

  end

  defp update_token({:ok, access_token, expires_in}) do
    now = :os.timestamp |> Duration.from_erl |> Duration.to_seconds
    Agent.update(:token, fn _ -> %{token: access_token, expires_in: now + expires_in }  end)
  end

  defp parse_token ({:ok, response}) do
    {:ok, response["access_token"], response["expires_in"]}
#    {:error, } "error" => "invalid_client", "error_description" => "Client Authentication failed"}}
  end

  def headers, do: Enum.concat(request_headers(), authorization_header())

  defp authorization_header do
    %{token: access_token, expires_in: _expires_in} = token()
    [{"Authorization", "Bearer " <>  access_token}]
  end

  defp request_headers, do: [{"Accept", "application/json"}, {"Content-Type", "application/json"}]
  defp basic_headers, do: [{"Accept", "application/json"}, {"Content-Type", "application/x-www-form-urlencoded"}]

end