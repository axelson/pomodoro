defmodule Pomodoro do
  @moduledoc """
  Documentation for Pomodoro.
  """
  use Boundary, deps: [], exports: [PomodoroTimer]

  defdelegate slack_controls_enabled?(), to: Pomodoro.SlackControls, as: :enabled?
end
