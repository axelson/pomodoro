defmodule ScenicUtils.ScenicEntity.Pomodoro.PomodoroTimerTest do
  use ExUnit.Case, async: true
  use Machete

  alias Pomodoro.PomodoroTimer
  alias ScenicUtils.ScenicEntity.Pomodoro.PomodoroTimer, as: ProtocolImpl

  test "text_render/1 with a nil time" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: nil}

    graph = %Scenic.Graph{} = ProtocolImpl.text_render(Scenic.Graph.build(), pomodoro_timer)

    assert non_root_primitives(graph) ~>
             [
               struct_like(Scenic.Primitive, %{
                 module: Scenic.Primitive.Text,
                 data: "00:00",
                 styles: superset(%{
                   fill: {:color, {:color_rgba, {255, 255, 255, 255}}}
                 })
               })
             ]
  end

  test "timer_text/1 with no time remaining" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 0}

    graph = %Scenic.Graph{} = ProtocolImpl.text_render(Scenic.Graph.build(), pomodoro_timer)

    assert non_root_primitives(graph) ~>
             [
               struct_like(Scenic.Primitive, %{
                 module: Scenic.Primitive.Text,
                 data: "00:00",
                 styles: superset(%{
                   fill: {:color, {:color_rgba, {255, 255, 255, 255}}}
                 })
               })
             ]
  end

  test "timer_text/1 with a time in minutes" do
    pomodoro_timer = %PomodoroTimer{seconds_remaining: 200}

    graph = %Scenic.Graph{} = ProtocolImpl.text_render(Scenic.Graph.build(), pomodoro_timer)

    assert non_root_primitives(graph) ~>
             [
               struct_like(Scenic.Primitive, %{
                 module: Scenic.Primitive.Text,
                 data: "03:20",
                 styles: superset(%{
                   fill: {:color, {:color_rgba, {255, 255, 255, 255}}}
                 })
               })
             ]
  end

  defp non_root_primitives(%Scenic.Graph{} = graph) do
    graph.primitives
    |> Enum.flat_map(fn {_idx, primitive} ->
      if primitive.id == :_root_ do
        []
      else
        [primitive]
      end
    end)
  end

end
