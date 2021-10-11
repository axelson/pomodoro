defmodule Pomodoro.Repo.Migrations.CreatePomodoros do
  use Ecto.Migration

  def change do
    create table(:pomodoro_logs) do
      add :started_at, :naive_datetime, null: false
      add :finished_at, :naive_datetime
      add :rest_started_at, :naive_datetime
      add :rest_finished_at, :naive_datetime
      add :total_seconds, :integer

      timestamps()
    end

    create table(:interruptions) do
      add :pomodoro_id, references(:pomodoros)
    end
  end
end
