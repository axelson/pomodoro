defmodule PomodoroUi.Application do
  def start(_type, _args) do
    children =
      [
        maybe_start_timer(),
        Pomodoro.Repo,
        {Task.Supervisor, name: :pomodoro_task_supervisor},
        maybe_start_scenic()
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp maybe_start_scenic do
    main_viewport_config = Application.get_env(:pomodoro, :viewport)

    if main_viewport_config do
      [
        {Scenic, [main_viewport_config]}
      ]
    else
      []
    end
  end

  defp maybe_start_timer do
    if Application.get_env(:pomodoro, :viewport) do
      Pomodoro.PomodoroTimer
    else
      []
    end
  end
end
