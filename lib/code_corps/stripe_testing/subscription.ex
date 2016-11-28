defmodule CodeCorps.StripeTesting.Subscription do
  def create(map, _opts \\ []) do
    {:ok, do_create(map)}
  end

  def retrieve(map, _opts \\ []) do
    {:ok, do_retrieve(map)}
  end

  defp do_create(_) do
    {:ok, date} = DateTime.from_unix(1479472835)

    {:ok, plan} = CodeCorps.StripeTesting.Plan.create(%{}, [])

    %Stripe.Subscription{
      application_fee_percent: 5.0,
      cancel_at_period_end: false,
      canceled_at: nil,
      created: date,
      current_period_end: date,
      current_period_start: date,
      customer: "cus_123",
      ended_at: nil,
      id: "sub_123",
      livemode: false,
      metadata: %{},
      plan: plan,
      quantity: 1000,
      source: nil,
      start: date,
      status: "active",
      tax_percent: nil,
      trial_end: nil,
      trial_start: nil
    }
  end

  defp do_retrieve(_) do
    {:ok, date} = DateTime.from_unix(1479472835)

    {:ok, plan} = CodeCorps.StripeTesting.Plan.create(%{}, [])

    %Stripe.Subscription{
      application_fee_percent: 5.0,
      cancel_at_period_end: false,
      canceled_at: nil,
      created: date,
      current_period_end: date,
      current_period_start: date,
      customer: "cus_123",
      ended_at: nil,
      id: "sub_123",
      livemode: false,
      metadata: %{},
      plan: plan,
      quantity: 1000,
      source: nil,
      start: date,
      status: "canceled",
      tax_percent: nil,
      trial_end: nil,
      trial_start: nil
    }
  end
end
