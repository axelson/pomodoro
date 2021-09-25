defmodule PomodoroUi.TimerComponent do
  @moduledoc """
  A simple timer scenic component that is able to count down or up from a given
  start time (and duration if counting down)
  """
  use Scenic.Component, has_children: false

  require Logger
  alias Scenic.Graph
  alias Pomodoro.PomodoroTimer

  defmodule State do
    defstruct [:graph, :pomodoro_timer]
  end

  @doc false
  @impl Scenic.Component
  def validate(opts) do
    if Keyword.keyword?(opts) do
      {:ok, opts}
    else
      :invalid_data
    end
  end

  @impl Scenic.Scene
  def init(scene, opts, _scenic_opts) do
    pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)
    PomodoroTimer.register(self())

    graph =
      Graph.build()
      |> ScenicUtils.ScenicRenderer.draw(pomodoro_timer)

    state = %State{
      graph: graph,
      pomodoro_timer: pomodoro_timer
    }

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_event(event, _from, scene) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:btn_left, 1, _, _}}, :timer_component, scene) do
    state = scene.assigns.state
    %State{graph: graph, pomodoro_timer: pomodoro_timer} = state
    %PomodoroTimer{status: status} = pomodoro_timer

    case status do
      :initial -> PomodoroTimer.start_ticking()
      :running -> PomodoroTimer.pause()
      :running_paused -> PomodoroTimer.start_ticking()
      :limbo -> nil
      :limbo_finished -> nil
      :resting -> PomodoroTimer.pause()
      :resting_paused -> PomodoroTimer.start_ticking()
      # TODO: This actually causes an exception...
      :finished -> PomodoroTimer.start_ticking()
    end

    graph = ScenicUtils.ScenicRenderer.draw(graph, pomodoro_timer)

    scene = push_graph(scene, graph)

    {:noreply, scene}
  end

  def handle_input(input, _context, scene) do
    Logger.warn("Unhandled input!: #{inspect(input)}")
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info({:pomodoro_timer, pomodoro_timer}, scene) do
    state = scene.assigns.state
    %State{graph: graph} = state
    graph = ScenicUtils.ScenicRenderer.draw(graph, pomodoro_timer)
    state = %State{state | pomodoro_timer: pomodoro_timer, graph: graph}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:noreply, scene}
  end
end
