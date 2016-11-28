defmodule CodeCorps.StripeService.Events.CustomerSubscriptionUpdated do
  import Ecto.Query

  alias CodeCorps.Project
  alias CodeCorps.Repo
  alias CodeCorps.StripeConnectAccount
  alias CodeCorps.StripeConnectCustomer
  alias CodeCorps.StripeConnectPlan
  alias CodeCorps.StripeConnectSubscription
  alias CodeCorps.StripeService.Adapters

  @api Application.get_env(:code_corps, :stripe)

  # def handle(%{"data" => %{"object" => %{"livemode" => false}}}), do: {:ok, :ignored_not_live}
  def handle(%{"data" => %{"object" => %{"id" => stripe_sub_id, "customer" => connect_customer_id}}}) do
    with %StripeConnectCustomer{stripe_connect_account: %StripeConnectAccount{id_from_stripe: connect_account_id}} <-
           retrieve_connect_customer(connect_customer_id),

         {:ok, %Stripe.Subscription{} = stripe_subscription} <-
           @api.Subscription.retrieve(stripe_sub_id, connect_account: connect_account_id),

         subscription <-
           load_subscription(stripe_sub_id),

         {:ok, params} <-
           stripe_subscription |> Adapters.StripeConnectSubscription.to_params(%{}),

         _subscription <-
           update_subscription(subscription, params),

         project <-
           get_project(subscription)
    do
      update_project_totals(project)
    else
      nil -> {:error, :not_found}
      %StripeConnectCustomer{stripe_connect_account: nil} -> {:error, :not_found}
    end
  end

  defp retrieve_connect_customer(connect_customer_id) do
    StripeConnectCustomer
    |> Repo.get_by(id_from_stripe: connect_customer_id)
    |> Repo.preload(:stripe_connect_account)
  end

  defp load_subscription(id_from_stripe) do
    StripeConnectSubscription
    |> Repo.get_by(id_from_stripe: id_from_stripe)
  end

  defp update_subscription(%StripeConnectSubscription{} = record, params) do
    record
    |> StripeConnectSubscription.webhook_update_changeset(params)
    |> Repo.update
  end

  defp get_project(%StripeConnectSubscription{stripe_connect_plan_id: stripe_connect_plan_id}) do
    plan =
      StripeConnectPlan
      |> Repo.get(stripe_connect_plan_id)
      |> Repo.preload(:project)

    plan.project
  end

  defp default_to_zero(nil), do: 0
  defp default_to_zero(value), do: value

  defp update_project_totals(%Project{id: project_id} = project) do
    total_monthly_donated =
      StripeConnectSubscription
      |> where([s], s.status == "active")
      |> Repo.aggregate(:sum, :quantity)

    total_monthly_donated = default_to_zero(total_monthly_donated)

    project
    |> Project.update_total_changeset(%{total_monthly_donated: total_monthly_donated})
    |> Repo.update
  end
end
