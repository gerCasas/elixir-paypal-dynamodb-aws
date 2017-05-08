defmodule Pay.Router do
  use Pay.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Pay do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/test/paypal/token", PageTestController, :token
    get "/test/dymeno/fetch", PageTestController, :dynamo_fetch
    get "/pay/:metodo_pago/:my_token/:importe", PageTestController, :pay
    get "/approve/:my_token", PageTestController, :approve
    get "/cancel/:my_token", PageTestController, :cancel
  end

  # Other scopes may use custom stacks.
  # scope "/api", Pay do
  #   pipe_through :api
  # end
end
