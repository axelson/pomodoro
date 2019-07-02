defmodule TimerUI.Components.CountdownClock do
  use Scenic.Component
  # use Scenic.Component, has_children: false

  import Scenic.Primitives, only: [text: 3]
  require Logger

  alias Scenic.Graph

  @default_initial_seconds 60 * 25
  @font_size 80

  defmodule State do
    defstruct [:graph, :initial_seconds, :timer]
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
  def init(opts, scenic_opts) do
    initial_seconds = Keyword.get(opts, :initial_seconds, @default_initial_seconds)
    text = timer_text(initial_seconds)

    graph =
      Graph.build()
      |> render_background(text, false)
      |> render_text(text)

    {:ok, timer} = Timer.CountdownTimer.start_link(initial_seconds: initial_seconds)
    Timer.CountdownTimer.register(self(), timer)
    state = %State{graph: graph, initial_seconds: initial_seconds, timer: timer}

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %State{timer: timer, graph: graph, initial_seconds: initial_seconds} = state
    :ok = Timer.CountdownTimer.start_ticking(timer)

    text = timer_text(initial_seconds)

    graph =
      graph
      |> Graph.modify(:background, &render_background(&1, text, true))

    state = %State{state | graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("UNHANDLED input in countdown clock, #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info({:tick, seconds}, state) do
    %State{graph: graph} = state

    text = timer_text(seconds)

    graph =
      graph
      |> Graph.modify(:background, &render_background(&1, text, true))
      |> Graph.modify(:timer, &render_text(&1, text))

    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end

  def timer_text(seconds), do: "Timer: #{seconds}"

  def render_text(graph, text) do
    graph
    |> text(text,
      id: :timer,
      t: {0, 0},
      fill: :white,
      text_align: :center_middle,
      font_size: @font_size
    )
  end

  def render_background(graph, text, timer_running?) do
    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, @font_size, fm)
    height = @font_size

    fill = if timer_running?, do: :green, else: :red

    x_pos = -width / 2
    y_pos = - @font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height}, id: :background, fill: fill, t: {x_pos, y_pos})
  end
end
