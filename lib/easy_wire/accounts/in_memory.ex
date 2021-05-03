defmodule EasyWire.Accounts.InMemory do
  alias EasyWire.Accounts.Account

  defstruct [:pid]

  def new(opts) do
    {:ok, pid} = start_link(opts)

    %__MODULE__{pid: pid}
  end

  def start_link(opts) do
    Agent.start_link(fn ->
      profile_ids = Keyword.get(opts, :profile_ids, [])
      generation_size = Keyword.get(opts, :generation_size, 10000)

      model = %{
        generation_size: generation_size,
        accounts: %{}
      }

      Enum.reduce(profile_ids, model, fn profile_id, model ->
        account = generate_account(model, profile_id)

        add_account(model, account)
      end)
    end)
  end

  def get_account_for_profile(%__MODULE__{pid: pid}, profile_id) do
    Agent.get(pid, fn model ->
      {:ok, get_account(model, profile_id)}
    end)
  end

  def deposit_money(%__MODULE__{pid: pid}, profile_id, amount) do
    Agent.get_and_update(pid, fn model ->
      updated =
        update_account(
          model,
          profile_id,
          &Map.update!(&1, :balance, fn balance -> balance + amount end)
        )

      {{:ok, get_account(updated, profile_id)}, updated}
    end)
  end

  defp add_account(model, account) do
    Map.update!(model, :accounts, &Map.put(&1, account.profile_id, account))
  end

  defp get_account(model, profile_id) do
    Map.get(model.accounts, profile_id)
  end

  defp update_account(model, profile_id, update_fn) do
    Map.update!(model, :accounts, &Map.update!(&1, profile_id, update_fn))
  end

  defp generate_account(model, profile_id) do
    Account.schema()
    |> Norm.gen()
    |> StreamData.resize(model.generation_size)
    |> Enum.at(0)
    |> Map.put(:profile_id, profile_id)
  end

  defimpl EasyWire.Accounts.Service do
    alias EasyWire.Accounts.InMemory

    defdelegate get_account_for_profile(service, profile_id), to: InMemory
    defdelegate deposit_money(service, profile_id, amount), to: InMemory
  end
end
