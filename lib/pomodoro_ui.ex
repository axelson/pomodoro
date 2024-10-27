defmodule PomodoroUi do
  @moduledoc """
  Base of scenic ui
  """
  use Boundary, deps: [Pomodoro, ScenicUtils], exports: []
end
