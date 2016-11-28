defmodule CodeCorps.StripeConnectEventsController do
  use CodeCorps.Web, :controller

  alias CodeCorps.StripeService.Events

  def create(conn, json) do
    result = handle(json)
    respond(conn, result)
  end

  def handle(%{"type" => "account.updated"} = attributes) do
    Events.AccountUpdated.handle(attributes)
  end

  def handle(%{"type" => "customer.subscription.updated"} = attributes) do
    Events.CustomerSubscriptionUpdated.handle(attributes)
  end

  def handle(_attributes), do: {:ok, :unhandled_event}

  def respond(conn, {:error, _error}) do
    conn |> send_resp(400, "")
  end
  def respond(conn, _) do
    conn |> send_resp(200, "")
  end
end
