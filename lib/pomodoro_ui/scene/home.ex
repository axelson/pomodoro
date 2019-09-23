defmodule PomodoroUi.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph
  alias Scenic.ViewPort

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Scene
  def init(_, scenic_opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(scenic_opts[:viewport])

    t = {width / 2, height / 2}

    # instantiate a timer
    {:ok, pomodoro_timer_pid} = PomodoroTimer.start_link([])
    pomodoro_timer = PomodoroTimer.get_timer()

    # insantiate a timer component
    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> PomodoroUi.RestButtonComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> Scenic.Components.button("Reset", id: :btn_reset, t: {10, 10}, button_font_size: 40)

    schedule_refresh()

    {:ok, %State{graph: graph, pomodoro_timer_pid: pomodoro_timer_pid}, push: graph}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    %State{graph: graph} = state
    schedule_refresh()
    {:noreply, state, push: graph}
  end

  @impl Scenic.Scene
  def filter_event({:click, :btn_reset}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.reset(pomodoro_timer_pid)
    {:halt, state}
  end

  def filter_event({:click, :btn_rest}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.rest(pomodoro_timer_pid)
    {:halt, state}
  end

  def filter_event(event, _from, state) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:halt, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
