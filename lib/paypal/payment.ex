defmodule Paypal.Payment do

  @derive [Poison.Encoder]
  defstruct intent: nil, payer: nil, transactions: nil, id: nil, op: nil, update: nil, redirect_urls: nil
  @type p :: %Paypal.Payment{intent: String.t, payer: any, transactions: list(any), redirect_urls: any,
                            id: integer, op: String.t, update: list(any)}


end

defimpl Payment, for: Paypal.Payment do

  @doc """
    Function to create a payment with Paypal. Receives a Dict with all information that is required by
    the Paypal API.

    Example of payment struct: %Paypal.Payment{"intent" => "sale", "payer" => %{"funding_instruments" => [%{"credit_card" => %{"billing_address" => %{"city" => "Saratoga", "country_code" => "US", "line1" => "111 First Street", "postal_code" => "95070", "state" => "CA"}, "cvv2" => "874", "expire_month" => 11, "expire_year" => 2018, "first_name" => "Betsy", "last_name" => "Buyer", "number" => "4417119669820331", "type" => "visa"}}], "payment_method" => "credit_card"}, "transactions" => [%{"amount" => %{"currency" => "USD", "details" => %{"shipping" => "0.03", "subtotal" => "7.41", "tax" => "0.03"}, "total" => "7.47"}, "description" => "This is the payment transaction description."}]}
    The information about the value of the keys are in https://developer.paypal.com/webapps/developer/docs/api/#create-a-payment

    Returns a Task.
  """
  def create_payment(payment) do
    Task.async(fn -> do_create_payment(payment) end)
  end

  defp do_create_payment(payment) do
    string_payment = format_create_payment_request  Poison.encode!(payment)
    IO.inspect(string_payment)
    IO.inspect(Paypal.Authentication.headers())

    HTTPoison.post(Paypal.Config.url <> "/payments/payment", string_payment,
      Paypal.Authentication.headers(), timeout: :infinity, recv_timeout: :infinity)
    |> Paypal.Config.parse_response
    end

    defp format_create_payment_request(payment) do
    String.replace(payment, ~s("op":null,), "")
    |> String.replace(~s("update":null,), "")
  end


  @doc """
  Function to get the status of the payment at Paypal. It returns the API JSON as a dict.
  It receives a Paypal.Payment struct with id.
  """
  def get_status(payment) do
    HTTPoison.get(Paypal.Config.url <> "/payments/payment/" <> payment.id, Paypal.Authentication.headers(),
      timeout: :infinity, recv_timeout: :infinity)
    |> Paypal.Config.parse_response
  end

#  @doc """
#  Use this call to execute (complete) a PayPal payment that has been approved by the payer.
#  You can optionally update transaction information when executing the payment by passing in one or more transactions.
#  You have to set at least: %Paypal.Payment{id: PAYMENT_ID, payer: %{id: PAYER_ID}}
#
#  """
#  def execute_payment(payment) do
#    Task.async fn -> do_execute_payment(payment) end
#  end

  @doc """
  Use this call to get a list of payments in any state (created, approved, failed, etc.). The payments returned are the payments made to the merchant making the call.
  You should pass to this function just a empty Paypal.Payment like %Paypal.Payment{}
  """
  def get_payments(_payment) do
    HTTPoison.get(Paypal.Config.url <> "/payments/payment/", Paypal.Authentication.headers(), timeout: :infinity, recv_timeout: :infinity)
    |> Paypal.Config.parse_response
  end

  @doc """
  Use this call to refund a completed payment.
  Provide the sale_id in the URI and an empty JSON payload for a full refund.
  For partial refunds, you can include an amount.
  payment muast be:
  $Paypal.Payment{id: PAYMENT_ID, transactions: [%{total: TOTAL, currency: CURRENCY}]}
  """
  def refund(payment) do
    Task.async(fn -> do_execute_refund(payment) end)
  end

  defp do_execute_refund(payment) do

   refund = List.first(payment.transactions)

   HTTPoison.post(Paypal.Config.url <> "/payments/sale/#{payment.id}/refund",
     Poison.encode!(%{amount: %{total: refund.total, currency: refund.currency}}),
     Paypal.Authentication.headers(), timeout: :infinity, recv_timeout: :infinity)
   |> Paypal.Config.parse_response

  end

end