defmodule Pomodoro do
  @moduledoc """
  Documentation for Pomodoro.
  """
  use Boundary, deps: [ScenicUtils], exports: [PomodoroTimer]
  alias Pomodoro.Schemas
  alias Pomodoro.PomodoroTimer

  def registry, do: :pomodoro_registry

  def record_pomodoro_start(total_seconds, started_at \\ NaiveDateTime.utc_now()) do
    attrs = %{"started_at" => started_at, "total_seconds" => total_seconds}

    Schemas.PomodoroLog.changeset(%Schemas.PomodoroLog{}, attrs)
    |> Pomodoro.Repo.insert()
  end

  def update_pomodoro_log(%PomodoroTimer{pomodoro_log_id: nil}), do: nil

  def update_pomodoro_log(%PomodoroTimer{} = pomodoro_timer) do
    pomodoro_log = get_pomodoro_log!(pomodoro_timer.pomodoro_log_id)

    attrs = %{
      "total_seconds" => pomodoro_timer.total_seconds
    }

    Schemas.PomodoroLog.changeset(pomodoro_log, attrs)
    |> Pomodoro.Repo.update()
  end

  def create_pomodoro_log(attrs) do
    Schemas.PomodoroLog.changeset(%Schemas.PomodoroLog{}, attrs)
    |> Pomodoro.Repo.insert()
  end

  def update_pomodoro_log(%Schemas.PomodoroLog{} = pomodoro_log, attrs) do
    change_pomodoro_log(pomodoro_log, attrs)
    |> Pomodoro.Repo.update()
  end

  def change_pomodoro_log(%Schemas.PomodoroLog{} = pomodoro_log, attrs \\ %{}) do
    Schemas.PomodoroLog.changeset(pomodoro_log, attrs)
  end

  def delete_pomodoro_log(%Schemas.PomodoroLog{} = pomodoro_log) do
    Pomodoro.Repo.delete(pomodoro_log)
  end

  def mark_finished(
        %PomodoroTimer{} = pomodoro_timer,
        finished_at \\ NaiveDateTime.utc_now()
      ) do
    get_pomodoro_log!(pomodoro_timer.pomodoro_log_id)
    |> case do
      %Schemas.PomodoroLog{finished_at: nil} = pomodoro_log ->
        Schemas.PomodoroLog.changeset(pomodoro_log, %{"finished_at" => finished_at})
        |> Pomodoro.Repo.update()

      pomodoro_log ->
        pomodoro_log
    end
  end

  def mark_rest_started(
        %PomodoroTimer{} = pomodoro_timer,
        rest_started_at \\ NaiveDateTime.utc_now()
      ) do
    get_pomodoro_log!(pomodoro_timer.pomodoro_log_id)
    |> Schemas.PomodoroLog.changeset(%{"rest_started_at" => rest_started_at})
    |> Pomodoro.Repo.update()
  end

  def mark_rest_finished(
        %PomodoroTimer{} = pomodoro_timer,
        rest_finished_at \\ NaiveDateTime.utc_now()
      ) do
    get_pomodoro_log!(pomodoro_timer.pomodoro_log_id)
    |> Schemas.PomodoroLog.changeset(%{"rest_finished_at" => rest_finished_at})
    |> Pomodoro.Repo.update()
  end

  def get_pomodoro_log!(id), do: Pomodoro.Repo.get!(Schemas.PomodoroLog, id)
end
