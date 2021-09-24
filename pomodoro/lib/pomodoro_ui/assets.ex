defmodule PomodoroUi.Assets do
  use Scenic.Assets.Static,
    otp_app: :pomodoro,
    sources: [
      "assets",
      {:scenic, "deps/scenic/assets"}
    ],
    alias: [
      parrot: "images/parrot.jpg",
      roboto: {:scenic, "fonts/roboto.ttf"}
    ]
end
