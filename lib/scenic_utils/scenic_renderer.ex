defmodule ScenicUtils.ScenicRenderer do
  @moduledoc """
  Oversee the rendering of entities on a graph
  """

  alias Scenic.Graph

  @spec draw(Scenic.Graph.t(), ScenicUtils.ScenicEntity.entity()) :: Scenic.Graph.t()
  def draw(graph, {:delete, id}) do
    Graph.delete(graph, id)
  end

  def draw(graph, entity) do
    id = ScenicUtils.ScenicEntity.id(entity)

    case Graph.get(graph, id) do
      [] ->
        ScenicUtils.ScenicEntity.draw(entity, graph)

      # Work around not being able to modify a group primitive
      # Bug: https://github.com/boydm/scenic/issues/27
      [%{module: Scenic.Primitive.Group}] ->
        graph = Graph.delete(graph, id)
        ScenicUtils.ScenicEntity.draw(entity, graph)

      [_] ->
        Graph.modify(graph, id, fn graph ->
          ScenicUtils.ScenicEntity.draw(entity, graph)
        end)
    end
  end
end
