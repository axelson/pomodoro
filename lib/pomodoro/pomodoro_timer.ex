defmodule Pomodoro.PomodoroTimer do
  @moduledoc """
  Models a pomodoro timer.
  """

  use GenServer
  require Logger

  @me __MODULE__
  @default_total_seconds 30 * 60
  @default_max_rest_seconds 15 * 60
  @default_max_limbo_seconds 15 * 60
  @default_tick_duration 1_000

  defstruct [
    :total_seconds,
    :seconds_remaining,
    :max_rest_seconds,
    :max_limbo_seconds,
    :status,
    :tick_duration,
    :slack_enabled
  ]

  @typedoc """
  * :initial - Initial state
  * :running - The timer is currently running during a pomodoro work time
  * :running_paused - The timer is paused during a work time
  * :limbo - The work time has finished but an explicit rest has not yet begun
  * :limbo_finished - The limbo time has finished and the timer should stop ticking
  * :resting - The timer is currently running during a pomodoro rest time
  * :resting_paused - The timer is paused during a rest time
  * :finished - The work and rest time have both finished
  """
  @type status ::
          :initial
          | :running
          | :running_paused
          | :limbo
          | :limbo_finished
          | :resting
          | :resting_paused
          | :finished
  @type t :: %__MODULE__{
          total_seconds: pos_integer,
          # Counts down from total_seconds to -max_rest_seconds
          seconds_remaining: integer,
          max_rest_seconds: pos_integer,
          max_limbo_seconds: pos_integer,
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
    max_limbo_seconds = Keyword.get(opts, :max_limbo_seconds, @default_max_limbo_seconds)
    tick_duration = Keyword.get(opts, :tick_duration, @default_tick_duration)

    %__MODULE__{
      total_seconds: total_seconds,
      seconds_remaining: total_seconds,
      max_rest_seconds: max_rest_seconds,
      max_limbo_seconds: max_limbo_seconds,
      status: :initial,
      tick_duration: tick_duration,
      slack_enabled: true
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

  def add_time(name \\ @me, seconds) do
    GenServer.call(name, {:add_time, seconds})
  end

  def subtract_time(name \\ @me, seconds) do
    GenServer.call(name, {:subtract_time, seconds})
  end

  def rest(name \\ @me) do
    GenServer.call(name, :rest)
  end

  def reset(name \\ @me, opts \\ []) do
    GenServer.call(name, {:reset, opts})
  end

  def set_slack_enabled_status(name \\ @me, value) do
    GenServer.call(name, {:set_slack_enabled_status, value})
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
        new_status =
          case timer.status do
            :initial -> :running
            :running_paused -> :running
            :resting_paused -> :resting
          end

        %__MODULE__{timer | status: new_status}
      else
        timer
      end

    state = %State{state | timer: timer}
    notify_update(state)
    update_slack_status(timer)
    state = maybe_schedule_tick(state)
    {:reply, :ok, state}
  end

  def handle_call(:pause, _from, state) do
    state = cancel_timer(state)
    %State{timer: timer} = state

    new_status =
      case timer.status do
        :running -> :running_paused
        :resting -> :resting_paused
        status -> status
      end

    timer = %__MODULE__{timer | status: new_status}
    state = %State{state | timer_ref: nil, timer: timer}
    notify_update(state)
    update_slack_status(timer)
    {:reply, :ok, state}
  end

  def handle_call({:add_time, seconds}, _from, state) do
    %State{timer: timer} = state
    %__MODULE__{seconds_remaining: seconds_remaining} = timer
    timer = %__MODULE__{timer | seconds_remaining: seconds_remaining + seconds}
    state = %State{state | timer: timer}
    notify_update(state)
    {:reply, :ok, state}
  end

  def handle_call({:subtract_time, seconds}, _from, state) do
    %State{timer: timer} = state
    %__MODULE__{seconds_remaining: seconds_remaining} = timer
    new_seconds = max(seconds_remaining - seconds, 0)
    timer = %__MODULE__{timer | seconds_remaining: new_seconds}
    state = %State{state | timer: timer}
    notify_update(state)
    {:reply, :ok, state}
  end

  def handle_call(:rest, _from, state) do
    %State{timer: timer} = state
    new_status = :resting
    timer = %__MODULE__{timer | status: new_status, seconds_remaining: 0}
    state = %State{state | timer: timer}

    state =
      state
      |> cancel_timer()
      |> maybe_schedule_tick()

    notify_update(state)
    update_slack_status(timer)
    {:reply, :ok, state}
  end

  def handle_call({:reset, opts}, _from, state) do
    state = cancel_timer(state)
    timer = new(opts)
    state = %State{state | timer: timer}
    notify_update(state)
    update_slack_status(timer)
    {:reply, :ok, state}
  end

  def handle_call({:set_slack_enabled_status, value}, _from, state) do
    %State{timer: timer} = state
    timer = %__MODULE__{timer | slack_enabled: value}
    state = %State{state | timer: timer}
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    # IO.puts("tick")
    state = tick_and_notify(state)

    state =
      %State{state | timer_ref: nil}
      |> maybe_schedule_tick()

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("PomodoroTimer Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp cancel_timer(state) do
    %State{timer_ref: timer_ref} = state

    if timer_ref do
      Process.cancel_timer(timer_ref)
    end

    %State{state | timer_ref: nil}
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
      max_rest_seconds: max_rest_seconds,
      max_limbo_seconds: max_limbo_seconds,
      status: status
    } = timer

    timer =
      cond do
        status == :running && seconds_remaining <= 0 ->
          %__MODULE__{timer | status: :limbo}

        status == :limbo && seconds_remaining <= -max_limbo_seconds ->
          %__MODULE__{timer | status: :limbo_finished}

        status == :resting && seconds_remaining <= -max_rest_seconds ->
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
    %State{timer: timer, timer_ref: timer_ref} = state
    %__MODULE__{status: status, tick_duration: tick_duration} = timer

    if tick?(status) && is_nil(timer_ref) do
      timer_ref = Process.send_after(self(), :tick, tick_duration)
      %State{state | timer_ref: timer_ref}
    else
      state
    end
  end

  defp update_slack_status(%__MODULE__{slack_enabled: false}), do: nil

  defp update_slack_status(timer) do
    %__MODULE__{status: status, seconds_remaining: seconds_remaining} = timer

    case status do
      :initial -> clear_slack_status()
      :running -> set_slack_status(seconds_remaining)
      :running_paused -> clear_slack_status()
      :limbo -> nil
      :resting -> clear_slack_status()
      :resting_paused -> nil
      :finished -> clear_slack_status()
    end
  end

  defp set_slack_status(seconds_remaining) do
    Task.start(fn ->
      minutes = ceil(seconds_remaining / 60)
      Pomodoro.SlackControls.enable_dnd(minutes)
      Pomodoro.SlackControls.set_status("mid-pomodoro", ":tomato:", duration_minutes: minutes)
    end)
  end

  defp clear_slack_status do
    Task.start(fn ->
      Pomodoro.SlackControls.disable_dnd()
      Pomodoro.SlackControls.clear_status()
    end)
  end

  @spec tick?(status) :: boolean
  defp tick?(:initial), do: false
  defp tick?(:running), do: true
  defp tick?(:running_paused), do: false
  defp tick?(:limbo), do: true
  defp tick?(:limbo_finished), do: false
  defp tick?(:resting), do: true
  defp tick?(:resting_paused), do: false
  defp tick?(:finished), do: false

  # TODO: Should this be replaced with a state machine library?
  defp can_start_ticking?(:initial), do: true
  defp can_start_ticking?(:running), do: false
  defp can_start_ticking?(:running_paused), do: true
  defp can_start_ticking?(:limbo), do: false
  defp can_start_ticking?(:limbo_finished), do: false
  defp can_start_ticking?(:resting), do: false
  defp can_start_ticking?(:resting_paused), do: true
  defp can_start_ticking?(:finished), do: false
end
