defmodule TimerUI.TimerModel do
  defstruct [:seconds, :running?, :timer_ref]

  def new(initial_seconds) do
    {:ok, timer_ref} = TimerCore.CountdownTimer.start_link(initial_seconds: initial_seconds)
    %__MODULE__{seconds: initial_seconds, running?: false, timer_ref: timer_ref}
  end

  def tick(%__MODULE__{} = timer, seconds) do
    running? = seconds > 0
    %__MODULE__{timer | seconds: seconds, running?: running?}
  end

  def register_for_ticks(%__MODULE__{timer_ref: timer_ref} = timer) do
    :ok = TimerCore.CountdownTimer.register(self(), timer_ref)
    timer
  end

  def start_ticking(%__MODULE__{timer_ref: timer_ref} = timer) do
    :ok = TimerCore.CountdownTimer.start_ticking(timer_ref)
    %__MODULE__{timer | running?: true}
  end
end

defimpl ScenicEntity, for: TimerUI.TimerModel do
  alias Scenic.Primitives
  alias TimerUI.TimerModel

  @font_size 80

  def id(_), do: :timer_group

  def draw(timer, graph) do
    Primitives.group(
      graph,
      fn g ->
        g
        |> background_render(timer)
        |> text_render(timer)
      end,
      id: id(timer)
    )
  end

  def text_render(graph, %TimerModel{} = timer) do
    text = timer_text(timer)

    graph
    |> Primitives.text(text,
      t: {0, 0},
      fill: :white,
      text_align: :center_middle,
      font_size: @font_size
    )
  end

  def background_render(graph, %TimerModel{} = timer) do
    %TimerModel{running?: running?} = timer
    text = timer_text(timer)

    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, @font_size, fm)
    height = @font_size

    fill = if running?, do: :green, else: :red

    x_pos = -width / 2
    y_pos = -@font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height}, fill: fill, t: {x_pos, y_pos})
  end

  defp timer_text(timer) do
    %{seconds: total_seconds} = timer

    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end
end
