defmodule TimerUI.Components.CountdownClock do
  use Scenic.Component
  # use Scenic.Component, has_children: false

  import Scenic.Primitives, only: [text: 3]
  require Logger

  alias Scenic.Graph

  @default_initial_seconds 60 * 25

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

  @impl Scenic.Component
  def init(opts, scenic_opts) do
    initial_seconds = Keyword.get(opts, :initial_seconds, @default_initial_seconds)
    text = "Timer: #{initial_seconds}"
    font_size = 80

    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, font_size, fm)
    height = font_size

    graph =
      Graph.build()
      |> text(text, id: :timer, t: {0, 0}, text_align: :left_middle, font_size: font_size)
      |> Scenic.Primitives.rect({width, height}, t: {0, - height / 2})

    {:ok, timer} = Timer.CountdownTimer.start_link([initial_seconds: initial_seconds])
    Timer.CountdownTimer.register(self(), timer)
    state = %State{graph: graph, initial_seconds: initial_seconds, timer: timer}

    {:ok, state, push: graph}
  end

  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %State{timer: timer} = state
    :ok = Timer.CountdownTimer.start_ticking(timer)

    {:noreply, state}
  end

  def handle_input(event, _context, state) do
    Logger.info("UNHANDLED input in countdown clock, #{inspect event}")

    {:noreply, state}
  end

  def handle_info({:tick, seconds}, state) do
    %State{graph: graph} = state
    graph = Graph.modify(graph, :timer, &text(&1, "timer: #{seconds}", []))
    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end
end
