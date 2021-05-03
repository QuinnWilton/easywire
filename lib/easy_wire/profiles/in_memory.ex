defmodule EasyWire.Profiles.InMemory do
  alias EasyWire.Profiles.Profile

  defstruct [:pid]

  def new(opts) do
    {:ok, pid} = start_link(opts)

    %__MODULE__{pid: pid}
  end

  def start_link(opts) do
    Agent.start_link(fn ->
      profile_ids = Keyword.get(opts, :profile_ids, [])
      generation_size = Keyword.get(opts, :generation_size, 100)

      model = %{
        generation_size: generation_size,
        profiles: %{}
      }

      Enum.reduce(profile_ids, model, fn profile_id, model ->
        profile = generate_profile(model, profile_id)

        add_profile(model, profile)
      end)
    end)
  end

  def list_profiles(%__MODULE__{pid: pid}) do
    Agent.get(pid, fn model ->
      {:ok, Map.values(model.profiles)}
    end)
  end

  def get_profiles(%__MODULE__{pid: pid}, ids) do
    Agent.get(pid, fn model ->
      {:ok, Map.take(model.profiles, ids)}
    end)
  end

  def get_profile(%__MODULE__{pid: pid}, id) do
    Agent.get(pid, fn model ->
      {:ok, Map.get(model.profiles, id)}
    end)
  end

  def get_profile_from_session(%__MODULE__{pid: pid}, _session) do
    Agent.get(pid, fn model ->
      result =
        model.profiles
        |> Map.values()
        |> Enum.random()

      {:ok, result}
    end)
  end

  defp add_profile(model, profile) do
    Map.update!(model, :profiles, &Map.put(&1, profile.id, profile))
  end

  defp generate_profile(model, profile_id) do
    Profile.schema()
    |> Norm.gen()
    |> StreamData.resize(model.generation_size)
    |> Enum.at(0)
    |> Map.put(:id, profile_id)
  end

  defimpl EasyWire.Profiles.Service do
    alias EasyWire.Profiles.InMemory

    defdelegate list_profiles(service), to: InMemory
    defdelegate get_profiles(service, ids), to: InMemory
    defdelegate get_profile(service, id), to: InMemory
    defdelegate get_profile_from_session(service, sesson), to: InMemory
  end
end
