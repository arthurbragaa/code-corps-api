defmodule CodeCorps.StripeService.Events.AccountUpdated do
  alias CodeCorps.StripeService.Adapters
  alias CodeCorps.StripeConnectAccount
  alias CodeCorps.Repo

  @api Application.get_env(:code_corps, :stripe)

  # def handle(%{"data" => %{"object" => %{"livemode" => false}}}), do: {:ok, :ignored_not_live}
  def handle(%{"data" => %{"object" => %{"id" => id_from_stripe}}}) do
    with {:ok, %Stripe.Account{} = stripe_account} <-
           @api.Account.retrieve(id_from_stripe),
         %StripeConnectAccount{} = local_account <-
           Repo.get_by(StripeConnectAccount, id_from_stripe: id_from_stripe),
         {:ok, params} <-
           stripe_account |> Adapters.StripeConnectAccount.to_params(%{})
    do
      local_account
      |> StripeConnectAccount.webhook_update_changeset(params)
      |> Repo.update
    else
      nil -> {:error, :not_found}
    end
  end
end
