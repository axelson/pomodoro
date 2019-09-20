defprotocol ScenicUtils.ScenicEntity do
  @type id :: atom

  @typedoc "Any entity that can be drawn onto the graph"
  @type entity :: any

  @spec id(any) :: id()
  def id(data)

  @doc "Draw the entity onto the Graph"
  @spec draw(any, Scenic.Graph.t()) :: Scenic.Graph.t()
  def draw(data, graph)
end

# defmodule ScenicEntity.Behaviour do
#   @type id :: String.t()

#   @typedoc "Any entity that can be drawn onto the graph"
#   @type entity :: any

#   @callback id(entity) :: id()

#   @doc "Draw the entity onto the Graph"
#   @callback draw(entity, Scenic.Graph.t()) :: Scenic.Graph.t()
# end
