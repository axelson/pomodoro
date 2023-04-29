defmodule PomodoroUi.Assets do
  use Scenic.Assets.Static, otp_app: :pomodoro

  def asset_path, do: Path.join([__DIR__, "..", "..", "assets"]) |> Path.expand()
end
