defmodule Timer do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    children = []

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
