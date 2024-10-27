defmodule PomodoroUi.Application do
  def start(_type, _args) do
    children =
      [
        List.wrap(maybe_start_timer()),
        Pomodoro.Repo,
        {Task.Supervisor, name: :pomodoro_task_supervisor},
        List.wrap(maybe_start_scenic())
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp maybe_start_scenic do
    if main_viewport_config = Application.get_env(:pomodoro, :viewport) do
      [
        {Scenic, [main_viewport_config]}
      ]
    end
  end

  defp maybe_start_timer do
    if Application.get_env(:pomodoro, :viewport) do
      Pomodoro.PomodoroTimer
    end
  end
end
