defimpl ScenicUtils.ScenicEntity, for: Pomodoro.PomodoroTimer do
  use Boundary, classify_to: Pomodoro

  alias Scenic.Primitives
  alias Pomodoro.PomodoroTimer

  @font_size 80

  def id(_), do: :timer_group

  def draw(pomodoro_timer, graph) do
    Primitives.group(
      graph,
      fn g ->
        g
        |> background_render(pomodoro_timer)
        |> text_render(pomodoro_timer)
      end,
      id: id(pomodoro_timer)
    )
  end

  def text_render(graph, pomodoro_timer) do
    text = timer_text(pomodoro_timer)

    graph
    |> Primitives.text(text,
      t: {0, 0},
      fill: :white,
      text_align: :center_middle,
      font_size: @font_size
    )
  end

  def background_render(graph, pomodoro_timer) do
    %PomodoroTimer{status: status} = pomodoro_timer
    text = timer_text(pomodoro_timer)

    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, @font_size, fm)
    height = @font_size

    fill = background_color(status)
    x_pos = -width / 2
    y_pos = -@font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height}, fill: fill, t: {x_pos, y_pos})
  end

  @spec background_color(PomodoroTimer.status()) :: atom
  defp background_color(status)
  defp background_color(:initial), do: :green
  defp background_color(:running), do: :red
  defp background_color(:running_paused), do: :dark_khaki
  defp background_color(:limbo), do: :purple
  defp background_color(:limbo_finished), do: :purple
  defp background_color(:resting), do: :blue
  defp background_color(:resting_paused), do: :dodger_blue
  defp background_color(:finished), do: :purple

  def timer_text(pomodoro_timer) do
    %PomodoroTimer{seconds_remaining: seconds_remaining} = pomodoro_timer

    seconds_remaining = normalize_seconds_remaining(seconds_remaining)

    minutes = div(seconds_remaining, 60)
    seconds = rem(seconds_remaining, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end

  defp normalize_seconds_remaining(nil), do: 0
  defp normalize_seconds_remaining(seconds), do: abs(seconds)
end
