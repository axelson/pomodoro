defmodule TimerCoreTest do
  use ExUnit.Case
  doctest TimerCore

  test "greets the world" do
    assert TimerCore.hello() == :world
  end
end
