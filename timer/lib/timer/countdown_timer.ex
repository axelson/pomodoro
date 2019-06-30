defmodule Timer.CountdownTimer do
  use GenServer

  defmodule State do
    defstruct [:seconds, :listeners, :tick_duration, :timer_ref]
  end

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

  @impl GenServer
  def init(opts) do
    tick_duration = Keyword.get(opts, :tick_duration, 1_000)
    initial_seconds = Keyword.get(opts, :initial_seconds, 60 * 25)
    state = %State{seconds: initial_seconds, listeners: MapSet.new(), tick_duration: tick_duration}

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    state = add_listener(state, pid)
    {:reply, :ok, state}
  end

  def handle_call({:start_ticking}, _from, state) do
    state = schedule_tick(state)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    %State{seconds: seconds, listeners: listeners} = state

    state = %State{state | seconds: seconds - 1, timer_ref: nil}
    state = schedule_tick(state)

    Enum.each(listeners, fn listener -> Process.send(listener, {:tick, state.seconds}, []) end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = remove_listener(state, pid)
    {:noreply, state}
  end

  defp add_listener(%State{listeners: listeners} = state, pid) do
    %State{state | listeners: MapSet.put(listeners, pid)}
  end

  defp remove_listener(%State{listeners: listeners} = state, pid) do
    %State{state | listeners: MapSet.delete(listeners, pid)}
  end

  defp schedule_tick(%State{timer_ref: nil, tick_duration: tick_duration} = state) do
    timer_ref = Process.send_after(self(), :tick, tick_duration)
    %State{state | timer_ref: timer_ref}
  end
end
