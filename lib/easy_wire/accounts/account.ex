defmodule EasyWire.Accounts.Account do
  import Norm

  alias EasyWire.Types

  defstruct [
    :profile_id,
    :balance
  ]

  def schema,
    do:
      schema(%__MODULE__{
        profile_id: Types.id(),
        balance: balance()
      })

  defp balance() do
    # generate mostly positive balances
    generator =
      StreamData.frequency([
        {3, StreamData.positive_integer()},
        {1, StreamData.integer()}
      ])

    with_gen(spec(is_integer), generator)
  end
end
