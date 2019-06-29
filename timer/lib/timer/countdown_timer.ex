defmodule Timer.CountdownTimer do
  use GenServer

  defmodule State do
    defstruct [:seconds, :listeners]
  end

  @doc """
  Register to receive a {:tick, seconds_remaining} message on every tick
  """
  def register(pid) do
    GenServer.call(self(), {:register, pid})
  end

  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(_opts) do
    state = %State{seconds: 60 * 25, listeners: MapSet.new()}

    Process.send(self(), :tick, [])

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:register, pid}, state) do
    Process.monitor(pid)
    state = add_listener(pid)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, 1_000)

    %State{seconds: seconds, listeners: listeners} = state
    state = %State{seconds: seconds - 1}

    Enum.each(listeners, fn listener -> Process.send(listener, {:tick, state.seconds}) end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = remove_listener(state, pid)
    {:noreply, state}
  end

  defp add_listener(%State{listeners: listeners} = state, pid) do
    %State{listeners: MapSet.put(listeners, pid)}
  end

  defp remove_listener(%State{listeners: listeners} = state, pid) do
    %State{listeners: MapSet.delete(listeners, pid)}
  end
end
