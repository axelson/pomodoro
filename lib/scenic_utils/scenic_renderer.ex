defmodule ScenicUtils.ScenicRenderer do
  @moduledoc """
  Oversee the rendering of entities on a graph
  """

  # use Boundary, deps: [ScenicEntity], exports: [__MODULE__]

  alias Scenic.Graph

  @spec draw(ScenicEntity.entity(), Scenic.Graph.t()) :: Scenic.Graph.t()
  def draw({:delete, id}, graph) do
    Graph.delete(graph, id)
  end

  def draw(graph, entity) do
    IO.puts("before id!")
    IO.inspect(ScenicUtils.ScenicEntity, label: "ScenicUtils.ScenicEntity")
    functions = ScenicUtils.ScenicEntity.__info__(:functions)
    IO.inspect(functions, label: "functions")
    IO.inspect(entity, label: "entity")
    id = ScenicUtils.ScenicEntity.id(entity)
    IO.inspect(id, label: "id")

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
