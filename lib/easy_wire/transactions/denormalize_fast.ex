defmodule EasyWire.Transactions.DenormalizeFast do
  alias EasyWire.Transactions

  defstruct [
    :inner_service
  ]

  def new(inner_service) do
    %__MODULE__{inner_service: inner_service}
  end

  defimpl Transactions.Service do
    def get_total_pending_transactions(service, profile_id) do
      Transactions.Service.get_total_pending_transactions(
        service.inner_service,
        profile_id
      )
    end

    def get_total_processed_transactions(service, profile_id) do
      Transactions.Service.get_total_processed_transactions(
        service.inner_service,
        profile_id
      )
    end

    def post_transaction(service, sender_id, recipient_id, amount) do
      Transactions.Service.post_transaction(
        service.inner_service,
        sender_id,
        recipient_id,
        amount
      )
    end

    def list_transactions(service, profile_id, page, page_size) do
      with {:ok, transactions} <-
             Transactions.Service.list_transactions(
               service.inner_service,
               profile_id,
               page,
               page_size
             ) do
        profile_ids =
          Enum.flat_map(
            transactions.entries,
            &[&1.sender_id, &1.recipient_id]
          )

        profiles = get_profiles(profile_ids)

        result =
          Map.update!(transactions, :entries, fn entries ->
            Enum.map(entries, fn transaction ->
              %{
                transaction
                | sender: Map.get(profiles, transaction.sender_id),
                  recipient: Map.get(profiles, transaction.recipient_id)
              }
            end)
          end)

        {:ok, result}
      end
    end

    defp get_profiles(profile_ids) do
      get_profiles_result =
        ServiceMesh.call(
          :profiles,
          :get_profiles,
          [profile_ids]
        )

      case get_profiles_result do
        {:ok, profiles} -> profiles
        {:error, :econnrefused} -> %{}
      end
    end
  end
end
