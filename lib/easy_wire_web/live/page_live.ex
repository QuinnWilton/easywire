defmodule EasyWireWeb.PageLive do
  use EasyWireWeb, :live_view

  def mount(_params, session, socket) do
    if connected?(socket) do
      page = 1
      page_size = 5

      {:ok, profile} =
        ServiceMesh.call(
          :profiles,
          :get_profile_from_session,
          [session]
        )

      account = get_account(profile.id)
      transactions = get_transactions(profile.id, page, page_size)
      pending = get_pending_transactions(profile.id)
      processed = get_processed_transactions(profile.id)

      socket =
        socket
        |> assign(:page, page)
        |> assign(:page_size, page_size)
        |> assign(:profile, profile)
        |> assign(:account, account)
        |> assign(:transactions, transactions)
        |> assign(:pending, pending)
        |> assign(:processed, processed)

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  def handle_event("deposit", _value, socket) do
    {:ok, account} = deposit_money(socket.assigns.profile.id, 100)

    socket =
      socket
      |> assign(:account, account)

    {:noreply, socket}
  end

  def handle_event("post_transaction", _value, socket) do
    {:ok, profiles} = ServiceMesh.call(:profiles, :list_profiles, [])

    recipient =
      profiles
      |> Enum.reject(&(&1.id == socket.assigns.profile.id))
      |> Enum.random()

    # I know this code is incredibly unsafe. That's not the point :)
    {:ok, account} = deposit_money(socket.assigns.profile.id, -100)
    _ = deposit_money(recipient.id, 100)

    :ok =
      ServiceMesh.call(:transactions, :post_transaction, [
        socket.assigns.profile.id,
        recipient.id,
        100
      ])

    transactions =
      get_transactions(
        socket.assigns.profile.id,
        socket.assigns.page,
        socket.assigns.page_size
      )

    pending = get_pending_transactions(socket.assigns.profile.id)
    processed = get_processed_transactions(socket.assigns.profile.id)

    socket =
      socket
      |> assign(:account, account)
      |> assign(:transactions, transactions)
      |> assign(:pending, pending)
      |> assign(:processed, processed)

    {:noreply, socket}
  end

  def handle_event("previous_page", _value, socket) do
    {page, transactions} = change_page(socket, &(&1 - 1))

    socket =
      socket
      |> assign(:page, page)
      |> assign(:transactions, transactions)

    {:noreply, socket}
  end

  def handle_event("next_page", _value, socket) do
    {page, transactions} = change_page(socket, &(&1 + 1))

    socket =
      socket
      |> assign(:page, page)
      |> assign(:transactions, transactions)

    {:noreply, socket}
  end

  defp change_page(socket, f) do
    profile = socket.assigns.profile
    page = socket.assigns.page
    page_size = socket.assigns.page_size
    total_pages = socket.assigns.transactions.total_pages

    page = max(min(f.(page), total_pages), 1)
    transactions = get_transactions(profile.id, page, page_size)

    {page, transactions}
  end

  defp get_account(profile_id) do
    result =
      ServiceMesh.call(
        :accounts,
        :get_account_for_profile,
        [profile_id]
      )

    case result do
      {:ok, account} -> account
      {:error, :econnrefused} -> nil
    end
  end

  defp deposit_money(profile_id, amount) do
    ServiceMesh.call(
      :accounts,
      :deposit_money,
      [profile_id, amount]
    )
  end

  defp get_transactions(profile_id, page, page_size) do
    result =
      ServiceMesh.call(
        :transactions,
        :list_transactions,
        [profile_id, page, page_size]
      )

    case result do
      {:ok, transactions} -> transactions
      {:error, :econnrefused} -> nil
    end
  end

  defp get_processed_transactions(profile_id) do
    result =
      ServiceMesh.call(
        :transactions,
        :get_total_processed_transactions,
        [profile_id]
      )

    case result do
      {:ok, processed} -> processed
      {:error, :econnrefused} -> nil
    end
  end

  defp get_pending_transactions(profile_id) do
    result =
      ServiceMesh.call(
        :transactions,
        :get_total_pending_transactions,
        [profile_id]
      )

    case result do
      {:ok, pending} -> pending
      {:error, :econnrefused} -> nil
    end
  end

  defp transaction_message(current_user, transaction) do
    cond do
      is_nil(transaction.sender) or is_nil(transaction.recipient) ->
        "A network error has occurred"

      current_user.id == transaction.recipient.id ->
        "Received payment from #{transaction.sender.name}"

      current_user.id == transaction.sender.id ->
        "Sent payment to #{transaction.recipient.name}"
    end
  end

  defp transaction_status_style(status) do
    case status do
      :done -> "bg-green-100 text-green-800"
      :pending -> "bg-yellow-100 text-yellow-800"
      :failed -> "bg-gray-100 text-gray-800"
    end
  end
end
