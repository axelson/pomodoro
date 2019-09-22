defmodule Pomodoro.PomodoroTimer do
  @moduledoc """
  Models a pomodoro timer.
  """

  use GenServer

  @me __MODULE__
  @default_total_seconds 30 * 60
  @default_max_rest_seconds 15 * 60
  @default_tick_duration 1_000

  defstruct [:total_seconds, :seconds_remaining, :max_rest_seconds, :status, :tick_duration]

  @type status :: :initial | :running | :paused | :resting | :finished
  @type t :: %__MODULE__{
          total_seconds: pos_integer,
          # Counts down from total_seconds to -max_rest_seconds
          seconds_remaining: integer,
          max_rest_seconds: pos_integer,
          status: status
        }

  defmodule State do
    defstruct [:listeners, :timer, :timer_ref]

    @type t :: %__MODULE__{
            listeners: any,
            timer: Pomodoro.PomodoroTimer.t(),
            timer_ref: reference
          }
  end

  def new(opts \\ []) do
    total_seconds = Keyword.get(opts, :total_seconds, @default_total_seconds)
    max_rest_seconds = Keyword.get(opts, :max_rest_seconds, @default_max_rest_seconds)
    tick_duration = Keyword.get(opts, :tick_duration, @default_tick_duration)

    %__MODULE__{
      total_seconds: total_seconds,
      seconds_remaining: total_seconds,
      max_rest_seconds: max_rest_seconds,
      status: :initial,
      tick_duration: tick_duration
    }
  end

  def start_link(opts) do
    GenServer.start_link(@me, opts, name: @me)
  end

  @impl GenServer
  def init(opts) do
    state = %State{listeners: MapSet.new(), timer: new(opts)}
    {:ok, state}
  end

  def get_timer(name \\ @me) do
    GenServer.call(name, :get_timer)
  end

  def register(pid, name \\ @me) do
    GenServer.call(name, {:register, pid})
  end

  def start_ticking(name \\ @me) do
    GenServer.call(name, :start_ticking)
  end

  def pause(name \\ @me) do
    GenServer.call(name, :pause)
  end

  @impl GenServer
  def handle_call(:get_timer, _from, state) do
    %State{timer: timer} = state
    {:reply, timer, state}
  end

  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    state = add_listener(state, pid)
    {:reply, :ok, state}
  end

  def handle_call(:start_ticking, _from, state) do
    %State{timer: timer} = state
    %__MODULE__{status: status} = timer

    timer =
      if can_start_ticking?(status) do
        %__MODULE__{timer | status: :running}
      else
        timer
      end

    state = %State{state | timer: timer}
    notify_update(state)
    maybe_schedule_tick(state)
    {:reply, :ok, state}
  end

  def handle_call(:pause, _from, state) do
    %State{timer_ref: timer_ref} = state
    Process.cancel_timer(timer_ref)
    notify_update(state)
    state = %State{state | timer_ref: nil}
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    IO.puts("tick")
    state = tick_and_notify(state)

    state =
      %State{state | timer_ref: nil}
      |> maybe_schedule_tick()

    {:noreply, state}
  end

  defp add_listener(%State{listeners: listeners} = state, pid) do
    %State{state | listeners: MapSet.put(listeners, pid)}
  end

  defp tick(timer) do
    %__MODULE__{seconds_remaining: seconds_remaining} = timer
    %__MODULE__{timer | seconds_remaining: seconds_remaining - 1}
  end

  # TODO: refactor, should probably break this up
  defp tick_and_notify(state) do
    %State{timer: timer} = state
    timer = tick(timer)
    state = %State{state | timer: timer}

    %__MODULE__{
      seconds_remaining: seconds_remaining,
      max_rest_seconds: max_rest_seconds
    } = timer

    timer =
      cond do
        seconds_remaining == 0 ->
          %__MODULE__{timer | status: :resting}

        seconds_remaining == -max_rest_seconds ->
          %__MODULE__{timer | status: :finished}

        true ->
          timer
      end

    state = %State{state | timer: timer}
    notify_update(state)
    state
  end

  defp notify_update(state) do
    %State{listeners: listeners, timer: timer} = state
    message = {:pomodoro_timer, timer}
    Enum.each(listeners, &Process.send(&1, message, []))
  end

  defp maybe_schedule_tick(state) do
    %State{timer: timer} = state
    %__MODULE__{status: status, tick_duration: tick_duration} = timer

    if tick?(status) do
      timer_ref = Process.send_after(self(), :tick, tick_duration)
      %State{state | timer_ref: timer_ref}
    else
      state
    end
  end

  @spec tick?(status) :: boolean
  defp tick?(:initial), do: false
  defp tick?(:running), do: true
  defp tick?(:paused), do: false
  defp tick?(:resting), do: true
  defp tick?(:finished), do: false

  # TODO: Should this be replaced with a state machine library?
  defp can_start_ticking?(:initial), do: true
  defp can_start_ticking?(:running), do: false
  defp can_start_ticking?(:paused), do: true
  defp can_start_ticking?(:resting), do: false
  defp can_start_ticking?(:finished), do: false
end
