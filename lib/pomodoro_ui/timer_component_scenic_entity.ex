defimpl ScenicUtils.ScenicEntity, for: Pomodoro.PomodoroTimer do
  use Boundary, classify_to: Pomodoro

  alias Scenic.Primitives

  alias Pomodoro.PomodoroUtils

  @font_size 80

  def id(_), do: :timer_group

  def draw(pomodoro_timer, graph) do
    Primitives.group(
      graph,
      fn g ->
        g
        |> background_render(pomodoro_timer)
        |> timer_label_render(pomodoro_timer)
        |> text_render(pomodoro_timer)
        |> extended_text(pomodoro_timer)
        |> status_text(pomodoro_timer)
      end,
      id: id(pomodoro_timer)
    )
  end

  def timer_label_render(graph, pomodoro_timer) do
    {width, height} = {85, 71}

    fill =
      case timer_label_fill_type(pomodoro_timer.status) do
        :none -> :clear
        :working -> {:image, {:pomodoro, "images/timer_label_working.png"}}
        :resting -> {:image, {:pomodoro, "images/timer_label_resting.png"}}
      end

    graph
    |> Scenic.Primitives.rect(
      {width, height},
      fill: fill,
      t: {-width / 2, -150}
    )
  end

  defp timer_label_fill_type(:initial), do: :none
  defp timer_label_fill_type(:running), do: :working
  defp timer_label_fill_type(:running_paused), do: :working
  defp timer_label_fill_type(:limbo), do: :none
  defp timer_label_fill_type(:limbo_finished), do: :none
  defp timer_label_fill_type(:resting), do: :resting
  defp timer_label_fill_type(:resting_paused), do: :resting
  defp timer_label_fill_type(:finished), do: :resting

  def status_text(graph, pomodoro_timer) do
    graph
    |> Scenic.Primitives.text("status: #{pomodoro_timer.status}",
      id: :status_text,
      t: {100, 10},
      color: :white,
      text_base: :top,
      # This is for debugging so we leave it as hidden
      hidden: true
    )
  end

  def extended_text(graph, pomodoro_timer) do
    text = PomodoroUtils.timer_text(pomodoro_timer.extended_seconds)

    graph
    |> Scenic.Primitives.text(text,
      id: :extended_text,
      t: {0, 50},
      text_align: :center,
      color: :white,
      text_base: :middle
    )
  end

  def text_render(graph, pomodoro_timer) do
    text = PomodoroUtils.timer_text(pomodoro_timer.seconds_remaining)

    graph
    |> Primitives.text(text,
      t: {0, 0},
      fill: :white,
      text_align: :center,
      text_base: :middle,
      font_size: @font_size
    )
  end

  def background_render(graph, pomodoro_timer) do
    text = PomodoroUtils.timer_text(pomodoro_timer.seconds_remaining)

    {:ok, {_type, fm}} = Scenic.Assets.Static.meta(:roboto)
    width = FontMetrics.width(text, @font_size, fm)
    height = @font_size

    x_pos = -width / 2
    y_pos = -@font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height},
      fill: :clear,
      t: {x_pos, y_pos},
      id: :timer_component,
      input: [:cursor_button]
    )
  end
end
