defmodule PomodoroUi do
  @moduledoc """
  Base of scenic ui
  """
  use Boundary, deps: [Pomodoro, ScenicUtils], exports: []

  def start(_type, _args) do
    main_viewport_config = Application.get_env(:pomodoro, :viewport)

    children = [
      {Scenic, viewports: [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
