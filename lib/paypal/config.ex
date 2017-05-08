defmodule Paypal.Config do
  @api_url "https://api.sandbox.paypal.com/v1"
#  @api_url "https://api.paypal.com/v1"
  @sand_box_url "https://api.sandbox.paypal.com/v1"

  def url do
    case Application.get_env(:pay, :paypal)[:env] do
      :sandbox -> @sand_box_url
      _ -> @api_url
    end
  end


  def parse_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 401,  body: body, headers: _headers}} ->
        {:ok, response} = Poison.decode body
        {:auth_error, response}
      {:ok, %HTTPoison.Response{status_code: _, body: body, headers: _headers}} ->
        {:ok, Poison.decode! body}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:nok, reason}
    end
  end

end