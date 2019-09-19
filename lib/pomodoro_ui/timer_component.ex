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

defimpl ScenicUtils.ScenicEntity, for: Pomodoro.PomodoroTimer do
  alias Scenic.Primitives
  alias Pomodoro.PomodoroTimer

  @font_size 80

  def id(_), do: :timer_group

  def draw(pomodoro_timer, graph) do
    Primitives.group(
      graph,
      fn g ->
        g
        |> background_render(pomodoro_timer)
        |> text_render(pomodoro_timer)
      end,
      id: id(pomodoro_timer)
    )
  end

  def text_render(graph, pomodoro_timer) do
    text = timer_text(pomodoro_timer)

    graph
    |> Primitives.text(text,
      t: {0, 0},
      fill: :white,
      text_align: :center_middle,
      font_size: @font_size
    )
  end

  def background_render(graph, pomodoro_timer) do
    %PomodoroTimer{status: status} = pomodoro_timer
    text = timer_text(pomodoro_timer)

    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, @font_size, fm)
    height = @font_size

    fill = background_color(status)
    x_pos = -width / 2
    y_pos = -@font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height}, fill: fill, t: {x_pos, y_pos})
  end

  @spec background_color(PomodoroTimer.status()) :: atom
  defp background_color(status)
  defp background_color(:initial), do: :green
  defp background_color(:running), do: :red
  defp background_color(:paused), do: :green
  defp background_color(:resting), do: :blue
  defp background_color(:finished), do: :purple

  defp timer_text(pomodoro_timer) do
    %PomodoroTimer{seconds_remaining: seconds_remaining} = pomodoro_timer

    minutes = div(seconds_remaining, 60)
    seconds = rem(seconds_remaining, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end
end
