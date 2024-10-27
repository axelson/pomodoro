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
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)
    x1 = Keyword.get(opts, :x1)
    x2 = Keyword.get(opts, :x2)
    y = Keyword.get(opts, :y)
    PomodoroTimer.register()

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

  @impl ScenicUtils.ScenicRendererBehaviour
  def handle_message({:pomodoro_timer, pomodoro_timer}, state) do
    state = %State{state | pomodoro_timer: pomodoro_timer}
    {:redraw, state}
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def draw(graph, state) do
    %State{pomodoro_timer: pomodoro_timer} = state

    graph
    |> Scenic.Primitives.group(
      fn g -> render_buttons(g, pomodoro_timer) end,
      id: :time_controls
    )
  end

  defp render_buttons(g, pomodoro_timer) do
    g
    |> ScenicContrib.IconComponent.add_to_graph(
      [
        icon: {:pomodoro, "images/timer_plus_rest.png"},
        on_press_icon: {:pomodoro, "images/timer_plus_select.png"},
        width: 53,
        height: 43,
        on_click: &on_plus/1
      ],
      id: :btn_add_time,
      t: {602, 385},
      hidden: !visible(pomodoro_timer)
    )
    |> ScenicContrib.IconComponent.add_to_graph(
      [
        icon: {:pomodoro, "images/timer_minus_rest.png"},
        on_press_icon: {:pomodoro, "images/timer_minus_select.png"},
        width: 53,
        height: 43,
        on_click: &on_minus/1
      ],
      id: :btn_minus,
      t: {663, 385},
      hidden: !visible(pomodoro_timer)
    )
  end

  # Multiple HACKS here. The sleep is so that the timer doesn't get re-rendered
  # before it finishes showing the pressed state. I should investigate how the
  # official scenic button handles this
  # Other hack is sending a message directly to the pomodoro timer
  defp on_minus(_) do
    Process.sleep(100)
    :ok = PomodoroTimer.subtract_time(5 * 60)
  end

  defp on_plus(_) do
    Process.sleep(100)
    PomodoroTimer.add_time(5 * 60)
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
