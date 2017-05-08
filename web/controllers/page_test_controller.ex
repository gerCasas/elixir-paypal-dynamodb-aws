defmodule Pay.PageTestController do
  use Pay.Web, :controller
  use Timex
  require Logger

  alias ExAws.Dynamo

  defmodule User do
    @derive [ExAws.Dynamo.Encodable]
    defstruct [:email, :name, :age, :admin, :mymapa, :mymapa2, :mymapa3]
  end

  defmodule Paypal_pay do
    @derive [ExAws.Dynamo.Encodable]
    defstruct [:my_token, :datetime, :metodo_pago, :transaction_start, :transaction_success, :transaction_fail]
  end

  def index(conn, _params) do
    render conn, "index.html"
  end

  def token(conn, _params) do
    token = Paypal.Authentication.token()

    map_result = Map.put(%{}, :token, token.token)
    map_result = Map.put(map_result, :expires_in, token.expires_in)
    render conn, "index.json", %{data: map_result}
  end

  def dynamo_fetch(conn, _params) do

#    https://github.com/CargoSense/ex_aws
#    https://hexdocs.pm/ex_aws/ExAws.Dynamo.html
#    https://elixirnation.io/libraries/ex_aws-flexible-easy-to-use-set-of-clients-aws-apis-for-elixir

#    # Create a users table with a primary key of email [String]
#    # and 1 unit of read and write capacity
#    Dynamo.create_table("Users", "email", %{email: :string}, 1, 1)
#    |> ExAws.request!

    # user = %User{email: "bubba2@foo.com", name: "Bubba", age: 23, admin: false, mymapa: %{uno: "uno", dos: "dos", tres: "tres"}}
    # # Save the user
    # Dynamo.put_item("Users", user) |> ExAws.request!


    # UPDATE TEST - UPDATE TEST - UPDATE TEST - UPDATE TEST - UPDATE TEST

    # user = %User{email: "bubba2@foo.com", mymapa: %{uno: "asd", mymapainterno: %{uno: "2", dos: "3", tres: "4"}, tres: "qwe"}}

    user = %User{email: "bubba2@foo.com", mymapa: %{uno: "asd", mymapainterno: %{uno: "111", dos: "222", tres: "333"}, tres: "qwe"}}

    Dynamo.update_item("Users", %{email: user.email}, %{ return_values: "ALL_NEW",  expression_attribute_names: %{"#s" => "mymapa"}, update_expression: "SET #s.mymapainterno = :val1", expression_attribute_values: [val1: user.mymapa.mymapainterno] } ) |> ExAws.request!

    # UPDATE TEST - UPDATE TEST - UPDATE TEST - UPDATE TEST - UPDATE TEST


#    # Retrieve the user by email and decode it as a User struct.
#    result = Dynamo.get_item("Users", %{email: user.email})
#    |> ExAws.request!
#    |> Dynamo.decode_item(as: User)
#
#    IO.inspect(result)

    map_result = Map.put(%{}, :status, "ok")
    render conn, "index.json", %{data: map_result}
  end

  def dynamo_put_item_paypal_trasaction_start(my_token) do
    datetime_string = Timex.format!(Timex.now, "%FT%T%:z", :strftime)
    # datetime_casted = Timex.parse!(datetime_string, "%FT%T%:z", :strftime)
    paypal_pay = %Paypal_pay{my_token: my_token, datetime: datetime_string}
    Dynamo.put_item("Paypal_logs", paypal_pay) |> ExAws.request!
  end

  def dynamo_put_item(table, my_map) do
    datetime_string = Timex.format!(Timex.now, "%FT%T%:z", :strftime)
    my_map = Map.put_new(my_map, "datetime", datetime_string)
    Dynamo.put_item(table, my_map) |> ExAws.request!
  end

  def pay(conn, params) do

    map_result = case params["metodo_pago"] do
      nil ->
        Map.put(%{}, :status, "404")
      value ->
        case value do
          "paypal" ->
            # IO.puts("PAYPAL-PAYPAL-PAYPAL-PAYPAL")

            # dynamo_put_item_paypal_trasaction_start(params["my_token"])

            paypal_pay = %Paypal_pay{my_token: params["my_token"], metodo_pago: params["metodo_pago"]}
            dynamo_put_item("Paypal_logs", paypal_pay)
            pay_paypal conn, params

            Map.put(%{}, :status, "ok")

          "openpay" ->
            # IO.puts("OPENPAY-OPENPAY-OPENPAY-OPENPAY")
            Map.put(%{}, :status, "ok")

          _ ->
            # IO.puts("METODO PAGO NO ENCONTRADO")
            Map.put(%{}, :status, "404")
        end
    end

    render conn, "index.json", %{data: map_result}
  end

  def pay_paypal(conn, params) do
    # IO.puts("+++++++++++++++++")

    {:ok, the_result} = Task.await(Payment.create_payment(%Paypal.Payment{intent: "sale", payer: %{"payment_method"=> "paypal"}, transactions: [%{"amount" => %{"currency" => "USD", "total" => params["importe"]}}], redirect_urls: %{"return_url"=> Enum.join(["http://localhost:4000/approve/", params["my_token"]], "") , "cancel_url"=> Enum.join(["http://localhost:4000/cancel/", params["my_token"]], "")} }), 10000000)

    map_result = Map.put(%{}, :state, the_result["state"])
    map_result = Map.put(map_result, :id, the_result["id"])
    map_result = Map.put(map_result, :create_time, the_result["create_time"])
    map_result = Map.put(map_result, :approval_url, List.first(Enum.filter(the_result["links"], & &1["rel"] == "approval_url"))["href"])

    # IO.puts("$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
    IO.inspect(map_result)
    # IO.puts("$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

    datetime_string = Timex.format!(Timex.now, "%FT%T%:z", :strftime)
    paypal_pay = %Paypal_pay{my_token: params["my_token"], transaction_start: %{date_time: datetime_string, id: map_result.id, state: map_result.state}}

    Dynamo.update_item("Paypal_logs", %{my_token: paypal_pay.my_token}, %{ return_values: "ALL_NEW",  expression_attribute_names: %{"#s" => "transaction_start"}, update_expression: "SET #s = :val1", expression_attribute_values: [val1: paypal_pay.transaction_start] } ) |> ExAws.request!

    map_result = Map.put(%{}, :status, "ok")
    render conn, "index.json", %{data: map_result}
  end

  def approve(conn, params) do
    # IO.puts("The pay is approve")
    # IO.inspect(params)
    #  %{"PayerID" => "6NE4BDLD5NQ4G", "paymentId" => "PAY-7XR180287W4062224LDSTNFQ", "token" => "EC-1AJ43649JL3773535"}

    datetime_string = Timex.format!(Timex.now, "%FT%T%:z", :strftime)

    paypal_pay = %Paypal_pay{my_token: params["my_token"], transaction_success: %{date_time: datetime_string, PayerID: params["PayerID"], paymentId: params["paymentId"], token: params["token"]}}
    Dynamo.update_item("Paypal_logs", %{my_token: paypal_pay.my_token}, %{ return_values: "ALL_NEW",  expression_attribute_names: %{"#s" => "transaction_success"}, update_expression: "SET #s = :val1", expression_attribute_values: [val1: paypal_pay.transaction_success] } ) |> ExAws.request!

    map_result = Map.put(%{}, :status, "ok")
    render conn, "index.json", %{data: map_result}
    # render conn, "index.html"
  end

  def cancel(conn, params) do
    # IO.puts("The pay was cancelled")

    datetime_string = Timex.format!(Timex.now, "%FT%T%:z", :strftime)

    paypal_pay = %Paypal_pay{my_token: params["my_token"], transaction_fail: %{date_time: datetime_string, status: "The pay was cancelled"}}
    Dynamo.update_item("Paypal_logs", %{my_token: paypal_pay.my_token}, %{ return_values: "ALL_NEW",  expression_attribute_names: %{"#s" => "transaction_fail"}, update_expression: "SET #s = :val1", expression_attribute_values: [val1: paypal_pay.transaction_fail] } ) |> ExAws.request!

    map_result = Map.put(%{}, :status, "ok")
    render conn, "index.json", %{data: map_result}
    # render conn, "index.html"
  end

end
