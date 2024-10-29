defmodule Pomodoro.PomodoroTimerTest do
  use ExUnit.Case, async: true
  use Machete
  import FlexTest

  alias Pomodoro.PomodoroTimer

  flex_test "initial timer" do
    pid = start_timer(tick_duration: 10, total_seconds: 300)

    assert PomodoroTimer.get_timer(pid)
           ~> struct_like(PomodoroTimer, %{
             seconds_remaining: 300
           })
  end

  flex_test "ticks are received" do
    pid = start_timer(tick_duration: 10, total_seconds: 300)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(30)

    assert_received {:pomodoro_timer, timer1}
    assert timer1.status == :running
    assert timer1.seconds_remaining == 300

    assert_received {:pomodoro_timer, timer2}
    assert timer2.status == :running
    assert timer2.seconds_remaining == 299
  end

  flex_test "timer transitions to limbo" do
    pid = start_timer(tick_duration: 10, total_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(60)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo
  end

  flex_test "timer ticks up during limbo" do
    pid = start_timer(tick_duration: 10, total_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking()
    Process.sleep(60)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    Process.sleep(60)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :limbo
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo
    assert timer.seconds_remaining == -5
  end

  flex_test "can switch to rest mode" do
    pid = start_timer(tick_duration: 10, total_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(70)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo

    PomodoroTimer.rest(pid)
    Process.sleep(60)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, _timer}
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :resting
    assert timer.seconds_remaining <= -4
  end

  flex_test "rest mode max seconds" do
    pid = start_timer(tick_duration: 10, total_seconds: 5, max_rest_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(70)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo

    PomodoroTimer.rest(pid)
    Process.sleep(70)

    for _i <- 1..6 do
      assert_received {:pomodoro_timer, _timer}
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :finished
    assert timer.seconds_remaining == -5
  end

  flex_test "after finished, extended seconds counts up" do
    pid = start_timer(tick_duration: 10, total_seconds: 5, max_rest_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(70)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo

    PomodoroTimer.rest(pid)
    Process.sleep(70)

    for _i <- 1..6 do
      assert_received {:pomodoro_timer, _timer}
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :finished
    assert timer.extended_seconds == 0

    Process.sleep(20)

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :finished
    assert timer.extended_seconds == 1
  end

  flex_test "when running_paused, the timer does not tick" do
    pid = start_timer(tick_duration: 10, total_seconds: 5, max_rest_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(20)
    PomodoroTimer.pause(pid)

    for _i <- 1..2 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :running_paused

    Process.sleep(30)
    refute_received {:pomodoro_timer, _}
  end

  flex_test "when limbo_paused, the timer does not tick" do
    pid = start_timer(tick_duration: 10, total_seconds: 5, max_rest_seconds: 5)

    {:ok, _} = PomodoroTimer.register(pid)

    PomodoroTimer.start_ticking(pid)
    Process.sleep(70)

    for _i <- 1..5 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :running
    end

    assert_received {:pomodoro_timer, timer}
    assert timer.status == :limbo

    PomodoroTimer.pause(pid)
    Process.sleep(60)

    for _i <- 1..2 do
      assert_received {:pomodoro_timer, timer}
      assert timer.status == :limbo
    end

    Process.sleep(30)
    refute_received {:pomodoro_timer, _}
  end

  defp start_timer(opts) do
    start_supervised!({PomodoroTimer, opts})
  end
end
