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
      |> draw(pomodoro_timer)

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

  @impl GenServer
  def handle_info({:pomodoro_timer, pomodoro_timer}, scene) do
    state = scene.assigns.state
    %State{graph: graph} = state

    graph =
      Graph.modify(graph, :btn_rest, fn graph ->
        graph
        |> draw(pomodoro_timer)
      end)

    state = %State{state | graph: graph}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:noreply, scene}
  end

  defp draw(graph, pomodoro_timer) do
    text = "Rest"
    font_size = 40

    {:ok, {_type, fm}} = Scenic.Assets.Static.fetch(:roboto)
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
