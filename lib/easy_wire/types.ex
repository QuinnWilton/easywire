defmodule EasyWire.Types do
  use ExUnitProperties
  import Norm

  def id do
    generator =
      StreamData.sized(fn _ ->
        StreamData.constant(Faker.UUID.v4())
      end)

    with_gen(spec(is_binary), generator)
  end

  def person_name() do
    generator =
      StreamData.sized(fn _ ->
        StreamData.constant(Faker.Person.name())
      end)

    with_gen(spec(is_binary), generator)
  end

  def date do
    with_gen(spec(is_struct()), date_generator())
  end

  def date_generator() do
    gen all year <- integer(1970..2050),
            month <- integer(1..12),
            day <- integer(1..31),
            match?({:ok, _}, Date.from_erl({year, month, day})) do
      Date.from_erl!({year, month, day})
    end
  end
end
