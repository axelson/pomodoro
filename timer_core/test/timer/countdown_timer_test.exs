defmodule TimerCore.CountdownTimerTest do
  use ExUnit.Case, async: true

  alias TimerCore.CountdownTimer

  @name :countdown_timer_test

  test "starts" do
    assert {:ok, pid} = CountdownTimer.start_link([], @name)
  end

  test "Does not send tick without starting" do
    opts = [tick_duration: 10, initial_seconds: 100]
    assert {:ok, _pid} = CountdownTimer.start_link(opts, @name)
    assert :ok = CountdownTimer.register(self(), @name)
    refute_receive {:tick, _seconds}, 100
  end

  test "registers and sends" do
    opts = [tick_duration: 10, initial_seconds: 100]

    assert {:ok, _pid} = CountdownTimer.start_link(opts, @name)
    assert :ok = CountdownTimer.register(self(), @name)
    assert :ok = CountdownTimer.start_ticking(@name)

    assert_receive {:tick, seconds}, 100
    assert seconds == 99
  end

  test "unregisters dead processes" do
    opts = [tick_duration: 10]

    assert {:ok, timer_pid} = CountdownTimer.start_link(opts, @name)

    {:ok, task_pid} =
      Task.start(fn ->
        assert_receive {:tick, _seconds}, 100
      end)

    assert :ok = CountdownTimer.register(task_pid, @name)
    assert :ok = CountdownTimer.register(self(), @name)
    assert :ok = CountdownTimer.start_ticking(@name)

    assert %{listeners: listeners} = :sys.get_state(timer_pid)
    assert MapSet.member?(listeners, task_pid)

    assert_receive {:tick, _seconds}, 100
    assert_receive {:tick, _seconds}, 100

    assert %{listeners: listeners} = :sys.get_state(timer_pid)
    refute MapSet.member?(listeners, task_pid)
  end

  test "stops ticking at 0" do
    opts = [tick_duration: 10, initial_seconds: 2]
    assert {:ok, _} = CountdownTimer.start_link(opts, @name)
    assert :ok = CountdownTimer.register(self(), @name)
    assert :ok = CountdownTimer.start_ticking(@name)
    assert_receive {:tick, 1}, 100
    assert_receive {:tick, 0}, 100
    refute_receive {:tick, _}, 50
  end
end
