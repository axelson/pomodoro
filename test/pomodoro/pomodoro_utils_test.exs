defmodule Pomodoro.PomodoroUtilsTest do
  use ExUnit.Case

  alias Pomodoro.PomodoroUtils

  test "timer_text/1 with a nil time" do
    assert PomodoroUtils.timer_text(nil) == "00:00"
  end

  test "timer_text/1 with no time remaining" do
    assert PomodoroUtils.timer_text(0) == "00:00"
  end

  test "timer_text/1 with a time in the seconds" do
    assert PomodoroUtils.timer_text(2) == "00:02"
  end

  test "timer_text/1 with a time in minutes" do
    assert PomodoroUtils.timer_text(200) == "03:20"
  end

  test "timer_text/1 with a very large time" do
    # Display will just grow larger (even if it doesn't all fit on the screen)
    assert PomodoroUtils.timer_text(9900) == "165:00"
  end

  test "timer_text/1 with negative time in the seconds" do
    assert PomodoroUtils.timer_text(-5) == "00:05"
  end

  test "timer_text/1 with negative time in the minutes" do
    assert PomodoroUtils.timer_text(-91) == "01:31"
  end
end
