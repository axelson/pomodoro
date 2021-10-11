defmodule ScenicUtils.ScenicEntity.Pomodoro.PomodoroTimerTest do
  use ExUnit.Case, async: true

  alias Pomodoro.PomodoroTimer
  alias ScenicUtils.ScenicEntity.Pomodoro.PomodoroTimer, as: ProtocolImpl

  test "timer_text/1 with a nil time" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: nil}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "00:00"
  end

  test "timer_text/1 with no time remaining" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 0}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "00:00"
  end

  test "timer_text/1 with a time in the seconds" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 2}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "00:02"
  end

  test "timer_text/1 with a time in minutes" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 200}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "03:20"
  end

  test "timer_text/1 with a very large time" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 9900}
    # Display will just grow larger (even if it doesn't all fit on the screen)
    assert ProtocolImpl.timer_text(pomodoro_timer) == "165:00"
  end

  test "timer_text/1 with negative time in the seconds" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: -5}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "00:05"
  end

  test "timer_text/1 with negative time in the minutes" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: -91}
    assert ProtocolImpl.timer_text(pomodoro_timer) == "01:31"
  end
end
