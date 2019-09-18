defmodule PomodoroUi.Scene.Home do
  use Scenic.Scene

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph
  alias Scenic.ViewPort

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(_, scenic_opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(scenic_opts[:viewport])

    t = {width / 2, height / 2}

    # instantiate a timer
    pomodoro_timer = PomodoroTimer.new()

    # insantiate a timer component
    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> Scenic.Components.button("Reset", id: :btn_reset, t: {10, 10}, button_font_size: 30)

    schedule_refresh()

    {:ok, %State{graph: graph}, push: graph}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    %State{graph: graph} = state
    schedule_refresh()
    {:noreply, state, push: graph}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
