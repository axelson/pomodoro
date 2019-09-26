defmodule PomodoroUi do
  @moduledoc """
  Base of scenic ui
  """
  use Boundary, deps: [Pomodoro, ScenicUtils], exports: []

  def start(_type, _args) do
    children =
      []
      |> maybe_add_scenic_child()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp maybe_add_scenic_child(children) do
    main_viewport_config = Application.get_env(:pomodoro, :viewport)

    if main_viewport_config do
      [{Scenic, viewports: [main_viewport_config]} | children]
    else
      children
    end
  end
end
