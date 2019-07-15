defmodule TimerCore.CountdownTimer do
  @moduledoc """
  A generic counting timer. Counts down or up, ticking every second. Processes
  can register for ticks and they'll be notified every tick.
  """

  use GenServer

  @type direction :: :count_up | :count_down
  @type option ::
          {:direction, direction}
          | {:tick_duration, pos_integer}
          | {:initial_seconds, pos_integer}
          | {:final_seconds, integer}

  defmodule State do
    defstruct [:direction, :seconds, :final_seconds, :listeners, :tick_duration, :timer_ref]

    @type t :: %{
            direction: TimerCore.CountdownTimer.direction(),
            seconds: pos_integer,
            final_seconds: integer,
            listeners: [pid],
            tick_duration: pos_integer,
            timer_ref: reference
          }
  end

  @spec start_link([option], atom) :: GenServer.on_start()
  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Register to receive a {:tick, seconds_remaining} message on every tick
  """
  def register(pid, name \\ __MODULE__) do
    GenServer.call(name, {:register, pid})
  end

  def start_ticking(name \\ __MODULE__) do
    GenServer.call(name, {:start_ticking})
  end

  def stop_ticking(name \\ __MODULE__) do
    GenServer.call(name, {:stop_ticking})
  end

  @impl GenServer
  def init(opts) do
    direction = Keyword.get(opts, :direction, :count_down)
    tick_duration = Keyword.get(opts, :tick_duration, 1_000)
    initial_seconds = Keyword.get(opts, :initial_seconds, 60 * 25)
    final_seconds = Keyword.get(opts, :final_seconds, 0)

    state = %State{
      direction: direction,
      seconds: initial_seconds,
      final_seconds: final_seconds,
      listeners: MapSet.new(),
      tick_duration: tick_duration
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    state = add_listener(state, pid)
    {:reply, :ok, state}
  end

  def handle_call({:start_ticking}, _from, state) do
    state = maybe_schedule_tick(state)

    {:reply, :ok, state}
  end

  def handle_call({:stop_ticking}, _from, state) do
    %State{timer_ref: timer_ref} = state
    _ = Process.cancel_timer(timer_ref)

    {:reply, :ok, %State{state | timer_ref: nil}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    state =
      %State{state | timer_ref: nil}
      |> tick_seconds()
      |> maybe_schedule_tick()

    notify_tick(state)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = remove_listener(state, pid)
    {:noreply, state}
  end

  defp notify_tick(state) do
    %State{seconds: seconds} = state
    notify(state, {:tick, seconds})
  end

  defp notify_finished(state), do: notify(state, {:finished})

  defp notify(state, message) do
    %State{listeners: listeners} = state

    Enum.each(listeners, &Process.send(&1, message, []))
  end

  defp tick_seconds(%State{direction: :count_down} = state) do
    %State{state | seconds: state.seconds - 1}
  end

  defp tick_seconds(%State{direction: :count_up} = state) do
    %State{state | seconds: state.seconds + 1}
  end

  defp add_listener(%State{listeners: listeners} = state, pid) do
    %State{state | listeners: MapSet.put(listeners, pid)}
  end

  defp remove_listener(%State{listeners: listeners} = state, pid) do
    %State{state | listeners: MapSet.delete(listeners, pid)}
  end

  defp maybe_schedule_tick(state) do
    %State{seconds: seconds, final_seconds: final_seconds, timer_ref: nil} = state

    if seconds == final_seconds do
      notify_finished(state)
      state
    else
      %State{tick_duration: tick_duration} = state
      timer_ref = Process.send_after(self(), :tick, tick_duration)
      %State{state | timer_ref: timer_ref}
    end
  end
end
