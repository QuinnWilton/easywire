defmodule EasyWire.Transactions.InMemory do
  alias EasyWire.Transactions.Transaction

  defstruct [:pid]

  def new(opts) do
    {:ok, pid} = start_link(opts)

    %__MODULE__{pid: pid}
  end

  def start_link(opts) do
    Agent.start_link(fn ->
      profile_ids = Keyword.get(opts, :profile_ids, [])
      number_of_transactions = Keyword.get(opts, :number_of_transactions, 100)
      generation_size = Keyword.get(opts, :generation_size, 100)

      model = %{
        generation_size: generation_size,
        history: []
      }

      model =
        Enum.reduce(1..number_of_transactions, model, fn _, model ->
          transaction = seed_transaction(model, profile_ids)

          add_transaction_to_history(model, transaction)
        end)

      Map.update!(model, :history, fn history ->
        Enum.sort(history, &(Date.compare(&1.date, &2.date) == :gt))
      end)
    end)
  end

  def list_transactions(
        %__MODULE__{pid: pid},
        profile_id,
        page,
        page_size
      ) do
    Agent.get(pid, fn model ->
      start_index = (page - 1) * page_size
      end_index = start_index + page_size - 1

      transactions =
        Enum.filter(
          model.history,
          &transaction_for_profile_id?(&1, profile_id)
        )

      total_entries = length(transactions)
      total_pages = trunc(Float.ceil(total_entries / page_size))

      {:ok,
       %{
         entries: Enum.slice(transactions, start_index..end_index),
         start: start_index,
         end: end_index,
         total_entries: total_entries,
         total_pages: total_pages
       }}
    end)
  end

  def get_total_pending_transactions(%__MODULE__{pid: pid}, profile_id) do
    Agent.get(pid, fn model ->
      result =
        model.history
        |> Enum.filter(&transaction_for_profile_id?(&1, profile_id))
        |> Enum.filter(&(&1.status == :pending))
        |> Enum.reduce(0, fn transaction, total ->
          cond do
            transaction.sender_id == profile_id ->
              total - transaction.amount

            transaction.recipient_id == profile_id ->
              total + transaction.amount
          end
        end)

      {:ok, result}
    end)
  end

  def get_total_processed_transactions(%__MODULE__{pid: pid}, profile_id) do
    Agent.get(pid, fn model ->
      result =
        model.history
        |> Enum.filter(&transaction_for_profile_id?(&1, profile_id))
        |> Enum.filter(&(&1.status == :done))
        |> Enum.reduce(0, fn transaction, total ->
          total + transaction.amount
        end)

      {:ok, result}
    end)
  end

  def post_transaction(%__MODULE__{pid: pid}, sender, recipient, amount) do
    Agent.update(pid, fn model ->
      transaction =
        model
        |> generate_transaction()
        |> Map.put(:sender_id, sender)
        |> Map.put(:recipient_id, recipient)
        |> Map.put(:amount, amount)
        |> Map.put(:status, :done)

      add_transaction_to_history(model, transaction)
    end)
  end

  defp add_transaction_to_history(model, transaction) do
    Map.update!(model, :history, &[transaction | &1])
  end

  def seed_transaction(model, profile_ids) do
    [sender_id, recipient_id] = generate_transaction_participants(profile_ids)

    model
    |> generate_transaction()
    |> Map.put(:sender_id, sender_id)
    |> Map.put(:recipient_id, recipient_id)
  end

  defp generate_transaction_participants(profile_ids) do
    profile_ids
    |> Enum.map(&StreamData.constant/1)
    |> StreamData.one_of()
    |> StreamData.uniq_list_of(length: 2)
    |> Enum.at(0)
  end

  defp generate_transaction(model) do
    Transaction.schema()
    |> Norm.gen()
    |> StreamData.resize(model.generation_size)
    |> Enum.at(0)
  end

  defp transaction_for_profile_id?(transaction, profile_id) do
    transaction.sender_id == profile_id or
      transaction.recipient_id == profile_id
  end

  defimpl EasyWire.Transactions.Service do
    alias EasyWire.Transactions.InMemory

    defdelegate list_transactions(service, profile_id, page, page_size),
      to: InMemory

    defdelegate get_total_pending_transactions(service, profile_id),
      to: InMemory

    defdelegate get_total_processed_transactions(service, profile_id),
      to: InMemory

    defdelegate post_transaction(service, sender, recipient, amount),
      to: InMemory
  end
end
