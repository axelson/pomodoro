defmodule Pomodoro.SoundPlayer do
  def play(_name) do
    sound_path = Path.join([:code.priv_dir(:pomodoro), "long.wav"])

    :exec.run_link("aplay #{sound_path}", [
      :stdout,
      :stderr,
      :stdin,
      :monitor
    ])
  end
end
