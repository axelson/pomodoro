defmodule ScenicRenderer do
  use Boundary, deps: [ScenicEntity], exports: []

  @moduledoc """
  Oversee the rendering of entities on a graph
  """

  alias Scenic.Graph

  @spec draw(ScenicEntity.entity(), Scenic.Graph.t()) :: Scenic.Graph.t()
  def draw({:delete, id}, graph) do
    Graph.delete(graph, id)
  end

  def draw(graph, entity) do
    id = ScenicEntity.id(entity)

    case Graph.get(graph, id) do
      [] ->
        ScenicEntity.draw(entity, graph)

      # Work around not being able to modify a group primitive
      # Bug: https://github.com/boydm/scenic/issues/27
      [%{module: Scenic.Primitive.Group}] ->
        graph = Graph.delete(graph, id)
        ScenicEntity.draw(entity, graph)

      [_] ->
        Graph.modify(graph, id, fn graph ->
          ScenicEntity.draw(entity, graph)
        end)
    end
  end
end
