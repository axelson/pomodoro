# state_server
defmodule Pomodoro.StateServer.PomodoroState do
  use StateServer,
    initial: [start_ticking: :running],
    running: [pause: :running_paused],
    running_paused: []

  # start_ticking: [initial: :running, running_paused: :running],
  # start_ticking: [initial: :running],
  # # rest: [running: :resting, limbo: :resting]
  # rest: [running: :resting]

  def start_link(opts \\ []) do
    StateServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl StateServer
  def init(opts) do
    IO.inspect(opts, label: "opts (pomodoro_state.ex:19)")
    state = []
    {:ok, state}
  end

  @impl StateServer
  def handle_call(from_state, _from, state, data) do
    IO.inspect(from_state, label: "from_state (pomodoro_state.ex:23)")
    {:reply, {state, data}}
    # {:reply, data, transition: :flip, update: [state | data], timeout: {:foo, 100}}
  end

  @impl StateServer
  def handle_transition(start, tr, data) do
    IO.puts("transitioned from #{start} through #{tr} with data #{inspect(data)}")
    :noreply
  end

  @impl StateServer
  def handle_timeout(_, _, _) do
    IO.puts("timed out!")
    :noreply
  end
end

defmodule Demo do
  use StateServer,
    on: [flip: :off, init: :initial],
    off: [flip: :on],
    initial: [start_ticking: :running],
    running: [pause: :running_paused],
    running_paused: []

  def start_link(_), do: StateServer.start_link(__MODULE__, [], name: Demo)

  @impl StateServer
  def init(_state), do: {:ok, []}

  @impl StateServer
  def handle_call(:flip, _from, state, data) do
    {:reply, data, transition: :flip, update: [state | data], timeout: {:foo, 100}}
  end

  def handle_call(from_state, _from, state, data) do
    IO.inspect(from_state, label: "from_state (pomodoro_state.ex:23)")
    {:reply, {state, data}}
    # {:reply, data, transition: :flip, update: [state | data], timeout: {:foo, 100}}
  end

  @impl StateServer
  def handle_transition(start, tr, data) do
    IO.puts("transitioned from #{start} through #{tr}")
    :noreply
  end

  @impl StateServer
  def handle_timeout(_, _, _) do
    IO.puts("timed out!")
    :noreply
  end
end

# machinery
defmodule Pomodoro.PomodoroStateMachinery do
  defstruct [:state]

  use Machinery,
    states: [
      "initial",
      "running",
      "running_paused",
      "limbo",
      "limbo_finished",
      "resting",
      "resting_paused",
      "finished"
    ],
    transitions: %{
      "initial" => ["running"],
      "running" => ["running_paused", "limbo", "finished"],
      "running_paused" => ["running"],
      "limbo" => ["limbo_finished", "resting", "finished"],
      "resting" => ["resting_paused", "finished"],
      "*" => ["initial"]
    }
end

# fsmx
defmodule Pomodoro.PomodoroStateFsmx do
  defstruct [:state, :data]

  # TODO: how do I name the transitions?
  use Fsmx.Struct,
    transitions: %{
      "initial" => ["running"],
      "running" => ["running_paused", "limbo", "finished"],
      "running_paused" => ["running"],
      "limbo" => ["limbo_finished", "resting", "finished"],
      "resting" => ["resting_paused", "finished"],
      :* => ["initial"]
    }
end

# finitomata
# defmodule MyFSM do
#   @fsm """
#   [*] --> s1 : to_s1
#   s1 --> s2 : to_s2
#   s1 --> s3 : to_s3
#   s2 --> [*] : ok
#   s3 --> [*] : ok
#   """

#   use Finitomata, @fsm

#   def on_transition(:s1, :to_s2, event_payload, state_payload),
#     do: {:ok, :s2, state_payload}

#   # def on_transition(…), do: …

#   # def on_failure(…), do: …

#   # def on_terminate(…), do: …
# end
