defmodule PomodoroUi.TimeControlsComponent do
  alias Pomodoro.PomodoroTimer

  @behaviour ScenicUtils.ScenicRendererBehaviour

  defmodule State do
    defstruct [:graph, :pomodoro_timer, :width, :height, :x1, :x2, :y]
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def id(_state), do: :time_controls

  @impl ScenicUtils.ScenicRendererBehaviour
  def init(opts, _scenic_opts) do
    pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)
    viewport = Keyword.fetch!(opts, :viewport)
    x1 = Keyword.get(opts, :x1)
    x2 = Keyword.get(opts, :x2)
    y = Keyword.get(opts, :y)
    PomodoroTimer.register(self())

    {:ok, %Scenic.ViewPort.Status{size: {width, height}}} = Scenic.ViewPort.info(viewport)

    state = %State{
      pomodoro_timer: pomodoro_timer,
      width: width,
      height: height,
      x1: x1,
      x2: x2,
      y: y
    }

    {:ok, state}
  end

  def handle_message({:pomodoro_timer, pomodoro_timer}, state) do
    state = %State{state | pomodoro_timer: pomodoro_timer}
    {:redraw, state}
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def draw(graph, state) do
    %State{pomodoro_timer: pomodoro_timer, width: width, height: height} = state

    graph
    |> Scenic.Primitives.group(
      fn g -> render_buttons(g, state, pomodoro_timer, width, height) end,
      id: :time_controls
    )
  end

  defp render_buttons(g, state, pomodoro_timer, width, height) do
    g
    |> Scenic.Components.button("-",
      id: :btn_subtract_time,
      t: left_t(state),
      width: 60,
      button_font_size: 30,
      hidden: !visible(pomodoro_timer)
    )
    |> Scenic.Components.button("+",
      id: :btn_add_time,
      t: right_t(state),
      width: 60,
      button_font_size: 30,
      hidden: !visible(pomodoro_timer)
    )
  end

  defp left_t(%State{x1: x1, y: y}) when not is_nil(x1) and not is_nil(y), do: {x1, y}
  defp left_t(%State{width: width, height: height}), do: {width / 2 - 85, height / 2 - 110}

  defp right_t(%State{x2: x2, y: y}) when not is_nil(x2) and not is_nil(y), do: {x2, y}
  defp right_t(%State{width: width, height: height}), do: {width / 2 + 25, height / 2 - 110}

  defp visible(%PomodoroTimer{status: :initial}), do: true
  defp visible(%PomodoroTimer{status: :running}), do: false
  defp visible(%PomodoroTimer{status: :running_paused}), do: true
  defp visible(%PomodoroTimer{status: :limbo}), do: false
  defp visible(%PomodoroTimer{status: :limbo_finished}), do: false
  defp visible(%PomodoroTimer{status: :resting}), do: false
  defp visible(%PomodoroTimer{status: :resting_paused}), do: true
  defp visible(%PomodoroTimer{status: :finished}), do: false
end
