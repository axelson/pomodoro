defmodule TimerUI.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  @text_size 24
  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # show the version of scenic and the glfw driver
    scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    glfw_ver = Application.spec(:scenic, :vsn) |> to_string()

    t = {width / 2, height / 2}

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> TimerUI.Components.CountdownClock.add_to_graph([initial_seconds: 10], id: :clock, t: t)

    schedule_refresh()

    {:ok, %State{graph: graph}, push: graph}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    schedule_refresh()
    {:noreply, state, push: state.graph}
  end

  def handle_info(msg, state) do
    Logger.info("Received info message: #{inspect msg}")
    {:noreply, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
