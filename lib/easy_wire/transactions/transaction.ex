defmodule EasyWire.Transactions.Transaction do
  use ExUnitProperties

  import Norm

  alias EasyWire.Types

  defstruct [
    :id,
    :sender_id,
    :recipient_id,
    :sender,
    :recipient,
    :amount,
    :status,
    :description,
    :date
  ]

  def schema,
    do:
      schema(%__MODULE__{
        id: Types.id(),
        sender_id: Types.id(),
        recipient_id: Types.id(),
        amount: amount(),
        status: status(),
        description: description(),
        date: Types.date()
      })

  defp amount() do
    spec(is_integer() and (&(&1 >= 0)))
  end

  defp status() do
    alt(
      done: :done,
      pending: :pending,
      failed: :failed
    )
  end

  defp description() do
    generator =
      StreamData.sized(fn _ ->
        StreamData.one_of([
          StreamData.constant(Faker.Commerce.product_name()),
          StreamData.constant(Faker.Food.dish()),
          StreamData.constant(Faker.Lorem.sentence())
        ])
      end)

    with_gen(spec(is_binary), generator)
  end
end
