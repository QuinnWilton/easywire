defmodule EasyWire.Profiles.Profile do
  import Norm

  alias EasyWire.Types

  defstruct [
    :id,
    :name,
    :trust,
    :company
  ]

  def schema,
    do:
      schema(%__MODULE__{
        id: Types.id(),
        name: Types.person_name(),
        trust: trust(),
        company: company()
      })

  defp trust() do
    alt(
      verified: :verified,
      unverified: :unverified
    )
  end

  defp company() do
    generator =
      StreamData.sized(fn _ ->
        StreamData.constant(Faker.Company.name())
      end)

    with_gen(spec(is_binary), generator)
  end
end
