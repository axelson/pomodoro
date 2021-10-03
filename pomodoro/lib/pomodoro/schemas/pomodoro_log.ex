defmodule Pomodoro.Schemas.PomodoroLog do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:started_at, :finished_at, :rest_started_at, :rest_finished_at, :total_seconds]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "pomodoro_logs" do
    field :started_at, :naive_datetime
    field :finished_at, :naive_datetime
    field :rest_started_at, :naive_datetime
    field :rest_finished_at, :naive_datetime
    field :total_seconds, :integer

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required([:started_at])
  end
end
