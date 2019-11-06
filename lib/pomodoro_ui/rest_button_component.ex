defmodule PomodoroUi.RestButtonComponent do
  @moduledoc """
  Display a button to start an explicit rest, only if the main timer has finished
  """
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Pomodoro.PomodoroTimer

  defmodule State do
    defstruct [:graph, :pomodoro_timer]
  end

  @doc false
  @impl Scenic.Component
  def info(data) do
    """
    #{IO.ANSI.red()}data must be a keyword list
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
    PomodoroTimer.register(self())

    graph =
      Graph.build()
      |> draw(pomodoro_timer)

    state = %State{
      graph: graph,
      pomodoro_timer: pomodoro_timer
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_info({:pomodoro_timer, pomodoro_timer}, state) do
    %State{graph: graph} = state

    graph =
      Graph.modify(graph, :btn_rest, fn graph ->
        graph
        |> draw(pomodoro_timer)
      end)

    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end

  defp draw(graph, pomodoro_timer) do
    font_size = 40
    font = :roboto

    text = "Rest"

    fm = Scenic.Cache.Static.FontMetrics.get!(font)
    ascent = FontMetrics.ascent(font_size, fm)
    fm_width = FontMetrics.width(text, font_size, fm)

    width = fm_width + ascent + ascent
    x_pos = -width / 2

    graph
    |> Scenic.Components.button(text,
      id: :btn_rest,
      t: {x_pos, 70},
      button_font_size: 40,
      hidden: hidden(pomodoro_timer)
    )
  end

  defp hidden(%PomodoroTimer{status: :initial}), do: true
  defp hidden(%PomodoroTimer{status: :running}), do: true
  defp hidden(%PomodoroTimer{status: :running_paused}), do: true
  defp hidden(%PomodoroTimer{status: :limbo}), do: false
  defp hidden(%PomodoroTimer{status: :limbo_finished}), do: false
  defp hidden(%PomodoroTimer{status: :resting}), do: true
  defp hidden(%PomodoroTimer{status: :resting_paused}), do: true
  defp hidden(%PomodoroTimer{status: :finished}), do: true
end
