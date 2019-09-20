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
  def info(data) do
    """
    #{IO.ANSI.red()}Clock data must be a keyword list
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  @doc false
  @impl Scenic.Component
  def verify(opts) do
    if Keyword.keyword?(opts) do
      {:ok, opts}
    else
      :invalid_data
    end
  end

  @impl Scenic.Scene
  def init(opts, _scenic_opts) do
    pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)

    graph =
      Graph.build()
      |> ScenicUtils.ScenicRenderer.draw(pomodoro_timer)

    state = %State{
      graph: graph,
      pomodoro_timer: pomodoro_timer
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %State{graph: graph, pomodoro_timer: pomodoro_timer} = state
    %PomodoroTimer{status: status} = pomodoro_timer

    case status do
      :initial -> PomodoroTimer.start_ticking()
      :running -> PomodoroTimer.pause()
      :paused -> PomodoroTimer.start_ticking()
      # TODO: Implement a built-in reset, or perhaps a non-automatic rest mode (which would be triggered with a start_rest)
      :resting -> PomodoroTimer.start_ticking()
      # TODO: This actually causes an exception...
      :finished -> PomodoroTimer.start_ticking()
    end

    graph = ScenicUtils.ScenicRenderer.draw(graph, pomodoro_timer)
    {:noreply, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_info({:tick, pomodoro_timer}, state) do
    %State{graph: graph} = state
    graph = ScenicUtils.ScenicRenderer.draw(graph, pomodoro_timer)
    state = %State{state | pomodoro_timer: pomodoro_timer, graph: graph}
    {:noreply, state, push: graph}
  end
end
