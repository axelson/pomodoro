defmodule Pomodoro.PomodoroUtils do
  alias Pomodoro.PomodoroTimer

  def timer_text(pomodoro_timer) do
    %PomodoroTimer{seconds_remaining: seconds_remaining} = pomodoro_timer

    seconds_remaining = normalize_seconds_remaining(seconds_remaining)

    minutes = div(seconds_remaining, 60)
    seconds = rem(seconds_remaining, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end

  defp normalize_seconds_remaining(nil), do: 0
  defp normalize_seconds_remaining(seconds), do: abs(seconds)
end
