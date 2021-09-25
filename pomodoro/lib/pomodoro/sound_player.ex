defmodule Pomodoro.SoundPlayer do
  def play(_name) do
    sound_path = Path.join([:code.priv_dir(:pomodoro), "long.wav"])
    MuonTrap.cmd("aplay", [sound_path])
  end
end
