defmodule Timer.Components.CountdownClock do
  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Graph
  alias Timer.TimerModel

  @default_initial_seconds 60 * 25

  defmodule State do
    defstruct [:graph, :initial_seconds, :timer, :timer_name]
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
    initial_seconds = Keyword.get(opts, :initial_seconds, @default_initial_seconds)
    timer_name = Keyword.fetch!(opts, :timer_name)

    timer =
      TimerModel.new(initial_seconds, timer_name)
      |> TimerModel.register_for_ticks()

    graph =
      Graph.build()
      |> ScenicRenderer.draw(timer)

    state = %State{graph: graph, timer: timer, timer_name: timer_name}

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %State{timer: timer, graph: graph, initial_seconds: initial_seconds, timer_name: timer_name} =
      state

    timer =
      case timer.status do
        :initial -> TimerModel.start_ticking(timer)
        :running -> TimerModel.stop_ticking(timer)
        :paused -> TimerModel.start_ticking(timer)
        :finished -> TimerModel.new(initial_seconds, timer_name)
      end

    graph =
      graph
      |> ScenicRenderer.draw(timer)

    state = %State{state | graph: graph, timer: timer}

    {:noreply, state, push: graph}
  end

  def handle_input(_event, _context, state) do
    # Logger.info("UNHANDLED input in countdown clock, #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info({:tick, seconds}, state) do
    %State{graph: graph, timer: timer} = state

    timer = TimerModel.tick(timer, seconds)

    graph =
      graph
      |> ScenicRenderer.draw(timer)

    state = %State{state | graph: graph, timer: timer}
    {:noreply, state, push: graph}
  end

  def handle_info({:finished}, state) do
    %State{graph: graph, timer: timer} = state

    timer = TimerModel.mark_finished(timer)

    graph =
      graph
      |> ScenicRenderer.draw(timer)

    state = %State{state | graph: graph, timer: timer}

    {:noreply, state, push: graph}
  end
end
