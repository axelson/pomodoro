defmodule ScenicUtils.ScenicRendererBehaviour do
  @moduledoc """
  Oversee the rendering of entities on a graph
  """

  use Scenic.Component, has_children: true

  alias Scenic.Graph

  @type id :: atom

  @callback id(any) :: id
  @callback init(opts :: Keyword.t(), scenic_opts :: Keyword.t()) :: {:ok, any}
  @callback draw(Scenic.Graph.t(), any) :: Scenic.Graph.t()

  defmodule State do
    defstruct [:mod, :graph, :component_state]
  end

  @impl Scenic.Component
  def info(data) do
    "Error, with interpreting #{inspect(data)}"
  end

  @impl Scenic.Component
  def verify(opts) do
    {:ok, opts}
  end

  @impl Scenic.Scene
  def init(opts, scenic_opts) do
    mod = Keyword.fetch!(opts, :mod)
    component_opts = Keyword.get(opts, :opts)

    case mod.init(component_opts, scenic_opts) do
      {:ok, component_state} ->
        graph = draw(Graph.build(), mod, component_state)
        state = %State{component_state: component_state, graph: graph, mod: mod}
        {:ok, state, push: graph}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl Scenic.Scene
  def handle_info(msg, state) do
    %State{mod: mod, component_state: component_state} = state

    case mod.handle_message(msg, component_state) do
      {:redraw, component_state} ->
        %State{graph: graph} = state
        state = %State{state | component_state: component_state}
        graph = draw(graph, mod, component_state)
        {:noreply, state, push: graph}

      {:ok, component_state} ->
        {:noreply, component_state}
    end
  end

  defp draw(graph, mod, component_state) do
    id = mod.id(component_state)

    case Graph.get(graph, id) do
      [] ->
        mod.draw(graph, component_state)

      # Work around not being able to modify a group primitive
      # Bug: https://github.com/boydm/scenic/issues/27
      [%{module: Scenic.Primitive.Group}] ->
        graph = Graph.delete(graph, id)
        mod.draw(graph, component_state)

      [_] ->
        Graph.modify(graph, id, fn graph ->
          mod.draw(graph, component_state)
        end)
    end
  end
end
