defmodule Pomodoro.PomodoroUtils do
  def timer_text(seconds) do
    seconds_remaining = normalize_seconds(seconds)

    minutes = div(seconds_remaining, 60)
    seconds = rem(seconds_remaining, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end

  defp normalize_seconds(nil), do: 0
  defp normalize_seconds(seconds), do: abs(seconds)
end
