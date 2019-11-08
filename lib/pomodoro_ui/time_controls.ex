defmodule PomodoroUi.TimeControlsComponent do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Pomodoro.PomodoroTimer

  defmodule State do
    defstruct [:graph, :viewport]
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
    viewport = Keyword.fetch!(opts, :viewport)
    PomodoroTimer.register(self())

    {:ok, %Scenic.ViewPort.Status{size: {width, height}}} = Scenic.ViewPort.info(viewport)

    graph =
      Graph.build()
      |> draw(pomodoro_timer, width, height)

    state = %State{viewport: viewport, graph: graph}
    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_info({:pomodoro_timer, pomodoro_timer}, state) do
    %State{graph: graph, viewport: viewport} = state
    {:ok, %Scenic.ViewPort.Status{size: {width, height}}} = Scenic.ViewPort.info(viewport)

    # Work around not being able to modify a group primitive
    # Bug: https://github.com/boydm/scenic/issues/27
    graph =
      graph
      |> Graph.delete(:time_controls)
      |> draw(pomodoro_timer, width, height)

    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end

  defp draw(graph, pomodoro_timer, width, height) do
    graph
    |> Scenic.Primitives.group(
      fn g ->
        g
        |> Scenic.Components.button("-",
          id: :btn_subtract_time,
          t: {width / 2 - 85, height / 2 - 110},
          width: 60,
          button_font_size: 30,
          hidden: !visible(pomodoro_timer)
        )
        |> Scenic.Components.button("+",
          id: :btn_add_time,
          t: {width / 2 + 25, height / 2 - 110},
          width: 60,
          button_font_size: 30,
          hidden: !visible(pomodoro_timer)
        )
      end,
      id: :time_controls
    )
  end

  defp visible(%PomodoroTimer{status: :initial}), do: true
  defp visible(%PomodoroTimer{status: :running}), do: false
  defp visible(%PomodoroTimer{status: :running_paused}), do: true
  defp visible(%PomodoroTimer{status: :limbo}), do: false
  defp visible(%PomodoroTimer{status: :limbo_finished}), do: false
  defp visible(%PomodoroTimer{status: :resting}), do: false
  defp visible(%PomodoroTimer{status: :resting_paused}), do: true
  defp visible(%PomodoroTimer{status: :finished}), do: false
end
