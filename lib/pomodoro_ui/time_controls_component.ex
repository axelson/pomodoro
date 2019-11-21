defmodule PomodoroUi.TimeControlsComponent do
  alias Pomodoro.PomodoroTimer

  @behaviour ScenicUtils.ScenicRendererBehaviour

  defmodule State do
    defstruct [:graph, :pomodoro_timer, :width, :height]
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def id(_state), do: :time_controls

  @impl ScenicUtils.ScenicRendererBehaviour
  def init(opts, _scenic_opts) do
    pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)
    viewport = Keyword.fetch!(opts, :viewport)
    PomodoroTimer.register(self())

    {:ok, %Scenic.ViewPort.Status{size: {width, height}}} = Scenic.ViewPort.info(viewport)

    state = %State{pomodoro_timer: pomodoro_timer, width: width, height: height}
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
      fn g -> render_buttons(g, pomodoro_timer, width, height) end,
      id: :time_controls
    )
  end

  defp render_buttons(g, pomodoro_timer, width, height) do
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
