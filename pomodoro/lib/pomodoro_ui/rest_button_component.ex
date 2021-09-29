defmodule PomodoroUi.RestButtonComponent do
  alias Pomodoro.PomodoroTimer

  @behaviour ScenicUtils.ScenicRendererBehaviour

  defmodule State do
    defstruct [:graph, :pomodoro_timer]
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def id(_state), do: :rest_button

  @impl ScenicUtils.ScenicRendererBehaviour
  def init(opts, _scenic_opts) do
    pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)
    PomodoroTimer.register(self())

    state = %State{
      pomodoro_timer: pomodoro_timer
    }

    {:ok, state}
  end

  def handle_message({:pomodoro_timer, pomodoro_timer}, state) do
    state = %State{state | pomodoro_timer: pomodoro_timer}
    {:redraw, state}
  end

  @impl ScenicUtils.ScenicRendererBehaviour
  def draw(graph, state) do
    %State{pomodoro_timer: pomodoro_timer} = state

    graph
    |> ScenicContrib.IconComponent.add_to_graph(
      [
        icon: {:pomodoro, "images/timer_break_rest.png"},
        on_press_icon: {:pomodoro, "images/timer_break_select.png"},
        width: 46,
        height: 62,
        on_click: &on_rest/0
      ],
      id: :btn_rest_icon,
      t: {522, 367},
      hidden: hidden(pomodoro_timer)
    )
  end

  defp on_rest do
    Process.sleep(100)
    :ok = PomodoroTimer.rest()
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
