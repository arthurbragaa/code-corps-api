defmodule CodeCorps.StripePlatformEventsControllerTest do
  use CodeCorps.ConnCase

  alias CodeCorps.StripeConnectAccount

  setup do
    conn =
      %{build_conn | host: "api."}
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  defp event_for(object) do
    %{
      "api_version" => "2016-07-06",
      "created" => 1326853478,
      "data" => %{
        "object" => object
      },
      "id" => "evt_00000000000000",
      "livemode" => false,
      "object" => "event",
      "pending_webhooks" => 1,
      "request" => nil,
      "type" => "account.updated"
    }
  end
end
