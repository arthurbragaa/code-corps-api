defmodule CodeCorps.StripeService.StripeConnectSubscription do
  alias CodeCorps.Organization
  alias CodeCorps.Project
  alias CodeCorps.Repo
  alias CodeCorps.StripeConnectAccount
  alias CodeCorps.StripeConnectCard
  alias CodeCorps.StripeConnectCustomer
  alias CodeCorps.StripeConnectPlan
  alias CodeCorps.StripeConnectSubscription
  alias CodeCorps.StripePlatformCard
  alias CodeCorps.StripePlatformCustomer
  alias CodeCorps.StripeService
  alias CodeCorps.StripeService.Adapters
  alias CodeCorps.User

  @api Application.get_env(:code_corps, :stripe)

  def create(%{"project_id" => project_id, "quantity" => quantity, "user_id" => user_id} = attributes) do
    with %Project{
           stripe_connect_plan: %StripeConnectPlan{} = plan,
           organization: %Organization{
             stripe_connect_account: %StripeConnectAccount{} = connect_account
           }
         } <-
           get_project(project_id),
         %User{
           stripe_platform_card: %StripePlatformCard{} = platform_card,
           stripe_platform_customer: %StripePlatformCustomer{} = platform_customer
         } <-
           get_user(user_id),
         {:ok, connect_customer} <-
           StripeService.StripeConnectCustomer.find_or_create(platform_customer, connect_account),
         {:ok, connect_card} <-
           StripeService.StripeConnectCard.find_or_create(platform_card, connect_customer, platform_customer, connect_account),
         create_attributes <-
           to_create_attributes(connect_card, connect_customer, plan, quantity),
         {:ok, subscription} <-
           @api.Subscription.create(create_attributes, connect_account: connect_account.id_from_stripe),
         insert_attributes <-
           to_insert_attributes(attributes, plan),
         {:ok, params} <-
           Adapters.StripeConnectSubscription.to_params(subscription, insert_attributes)
    do
      %StripeConnectSubscription{}
      |> StripeConnectSubscription.create_changeset(params)
      |> Repo.insert
    else
      {:error, error} -> {:error, error}
      nil -> {:error, :not_found}
    end
  end

  defp get_project(project_id) do
    Project
    |> Repo.get(project_id)
    |> Repo.preload([:stripe_connect_plan, [{:organization, :stripe_connect_account}]])
  end

  defp get_user(user_id) do
    User
    |> Repo.get(user_id)
    |> Repo.preload([stripe_platform_card: :stripe_connect_cards])
    |> Repo.preload(:stripe_platform_customer)
  end

  defp to_create_attributes(%StripeConnectCard{} = card, %StripeConnectCustomer{} = customer, %StripeConnectPlan{} = plan, quantity) do
    %{
      application_fee_percent: 5,
      customer: customer.id_from_stripe,
      plan: plan.id_from_stripe,
      quantity: quantity,
      source: card.id_from_stripe
    }
  end

  defp to_insert_attributes(attrs, %StripeConnectPlan{id: stripe_connect_plan_id}) do
    attrs |> Map.merge(%{"stripe_connect_plan_id" => stripe_connect_plan_id})
  end

  # TODO: Manual testing helpers, remove before merge

  def test do
    project = Project |> Repo.get(1)
    quantity = 10000
    user = CodeCorps.User |> Repo.get(5) |> Repo.preload([:stripe_platform_card])

    create(%{
      "project_id" => project.id,
      "quantity" => quantity,
      "user_id" => user.id
    })
  end

  def test_reset do
    CodeCorps.StripeConnectCard |> CodeCorps.Repo.all |> Enum.each(&CodeCorps.Repo.delete(&1))
    CodeCorps.StripeConnectCustomer |> CodeCorps.Repo.all |> Enum.each(&CodeCorps.Repo.delete(&1))
    CodeCorps.StripeConnectSubscription |> CodeCorps.Repo.all |> Enum.each(&CodeCorps.Repo.delete(&1))
  end

  def test_status do
    cards = CodeCorps.StripeConnectCard |> CodeCorps.Repo.aggregate(:count, :id)
    customers = CodeCorps.StripeConnectCustomer |> CodeCorps.Repo.aggregate(:count, :id)
    subscriptions = CodeCorps.StripeConnectSubscription |> CodeCorps.Repo.aggregate(:count, :id)

    IO.puts("\nCustomers: #{customers}, Cards: #{cards}, Subscriptions: #{subscriptions}\n")
  end
end
