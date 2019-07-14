defmodule Timer.TimerModel do
  defstruct [:seconds, :font_size, :status, :timer_ref]

  @type t :: %{
          seconds: integer,
          status: :initial | :running | :paused | :finished,
          font_size: pos_integer,
          timer_ref: any
        }

  def new(timer_opts, font_size, timer_name) do
    {:ok, timer_ref} = TimerCore.CountdownTimer.start_link(timer_opts, timer_name)

    %__MODULE__{
      seconds: timer_opts[:initial_seconds],
      status: :initial,
      timer_ref: timer_ref,
      font_size: font_size
    }
  end

  def tick(%__MODULE__{} = timer, seconds) do
    %__MODULE__{timer | seconds: seconds}
  end

  def register_for_ticks(%__MODULE__{timer_ref: timer_ref} = timer) do
    :ok = TimerCore.CountdownTimer.register(self(), timer_ref)
    timer
  end

  def start_ticking(%__MODULE__{timer_ref: timer_ref} = timer) do
    :ok = TimerCore.CountdownTimer.start_ticking(timer_ref)
    # TODO: Status should be controlled externally
    %__MODULE__{timer | status: :running}
  end

  def stop_ticking(%__MODULE__{timer_ref: timer_ref} = timer) do
    :ok = TimerCore.CountdownTimer.stop_ticking(timer_ref)
    # TODO: Status should be controlled externally
    %__MODULE__{timer | status: :paused}
  end

  def mark_finished(%__MODULE__{} = timer) do
    %__MODULE__{timer | status: :finished}
  end
end

defimpl ScenicEntity, for: Timer.TimerModel do
  alias Scenic.Primitives
  alias Timer.TimerModel

  @running_color :red
  @finished_color :blue
  @initial_color :green
  @paused_color :green

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
      font_size: font_size(timer)
    )
  end

  def background_render(graph, %TimerModel{} = timer) do
    %TimerModel{status: status} = timer
    text = timer_text(timer)
    font_size = font_size(timer)

    fm = Scenic.Cache.Static.FontMetrics.get!(:roboto)
    width = FontMetrics.width(text, font_size, fm)
    height = font_size

    fill =
      case status do
        :initial -> @initial_color
        :running -> @running_color
        :paused -> @paused_color
        :finished -> @finished_color
      end

    x_pos = -width / 2
    y_pos = -font_size / 2

    graph
    |> Scenic.Primitives.rect({width, height}, fill: fill, t: {x_pos, y_pos})
  end

  defp font_size(timer), do: timer.font_size

  defp timer_text(timer) do
    %{seconds: total_seconds} = timer

    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)

    minutes_text = String.pad_leading(to_string(minutes), 2, "0")
    seconds_text = String.pad_leading(to_string(seconds), 2, "0")

    "#{minutes_text}:#{seconds_text}"
  end
end
