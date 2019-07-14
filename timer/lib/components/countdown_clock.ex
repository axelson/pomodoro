defmodule Timer.Components.CountdownClock do
  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Graph
  alias Timer.TimerModel

  defmodule State do
    defstruct [:graph, :initial_seconds, :font_size, :timer, :timer_name, :on_finish]
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
    font_size = Keyword.fetch!(opts, :font_size)
    timer_name = Keyword.fetch!(opts, :timer_name)
    timer_opts = Keyword.fetch!(opts, :timer)
    on_finish = Keyword.get(opts, :on_finish)
    on_init = Keyword.get(opts, :on_init)
    start_immediately = Keyword.get(opts, :start_immediately, false)

    if on_init, do: on_init.()
    if start_immediately, do: Process.send(self(), {:start_ticking}, [])

    timer =
      TimerModel.new(timer_opts, font_size, timer_name)
      |> TimerModel.register_for_ticks()

    graph =
      Graph.build()
      |> ScenicRenderer.draw(timer)

    state = %State{
      graph: graph,
      timer: timer,
      timer_name: timer_name,
      font_size: font_size,
      on_finish: on_finish
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %State{
      timer: timer,
      graph: graph,
      initial_seconds: initial_seconds,
      timer_name: timer_name,
      font_size: font_size
    } = state

    timer =
      case timer.status do
        :initial -> TimerModel.start_ticking(timer)
        :running -> TimerModel.stop_ticking(timer)
        :paused -> TimerModel.start_ticking(timer)
        :finished -> TimerModel.new(initial_seconds, font_size, timer_name)
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

  def handle_info({:start_ticking}, state) do
    %State{timer: timer, graph: graph} = state
    timer = TimerModel.start_ticking(timer)

    graph =
      graph
      |> ScenicRenderer.draw(timer)

    state = %State{state | timer: timer, graph: graph}
    {:noreply, state, push: graph}
  end

  def handle_info({:finished}, state) do
    %State{graph: graph, timer: timer} = state

    timer = TimerModel.mark_finished(timer)

    if state.on_finish do
      state.on_finish.()
    end

    graph =
      graph
      |> ScenicRenderer.draw(timer)

    state = %State{state | graph: graph, timer: timer}

    {:noreply, state, push: graph}
  end

  def handle_info(msg, state) do
    IO.warn(msg, label: "UNHANDLED msg")
    {:noreply, state}
  end
end
