defmodule PomodoroUi do
  @moduledoc """
  Base of scenic ui
  """
  use Boundary, deps: [Pomodoro, ScenicUtils], exports: []

  def registry, do: :pomodoro_registry
end
