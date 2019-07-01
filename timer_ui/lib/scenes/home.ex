defmodule TimerUI.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @text_size 24

  defmodule State do
    defstruct [:graph, :timer]
  end

  @impl Scenic.Scene
  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # show the version of scenic and the glfw driver
    scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    glfw_ver = Application.spec(:scenic, :vsn) |> to_string()

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> TimerUI.Components.CountdownClock.add_to_graph([], id: :clock, t: {20, 400})

    {:ok, %State{graph: graph, timer: timer}, push: graph}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info(msg, state) do
    Logger.info("Received info message: #{inspect msg}")
    {:noreply, state}
  end
end
