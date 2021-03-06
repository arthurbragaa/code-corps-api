defmodule CodeCorps.DonationGoalController do
  use CodeCorps.Web, :controller
  use JaResource

  import CodeCorps.Helpers.Query, only: [id_filter: 2]

  alias CodeCorps.DonationGoal
  alias CodeCorps.DonationGoalsManager

  plug :load_and_authorize_changeset, model: DonationGoal, only: [:create]
  plug :load_and_authorize_resource, model: DonationGoal, only: [:update, :delete]
  plug JaResource

  def filter(_conn, query, "id", id_list), do: id_filter(query, id_list)

  def handle_create(_conn, attributes) do
    attributes
    |> DonationGoalsManager.create
  end

  def handle_update(_conn, record, attributes) do
    record
    |> DonationGoalsManager.update(attributes)
  end
end
