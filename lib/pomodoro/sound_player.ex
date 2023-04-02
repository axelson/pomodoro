defmodule Pomodoro.SoundPlayer do
  import HappyWith
  require Logger

  defp sound_name(:default), do: "default.wav"
  defp sound_name(:pomodoro_start), do: "pomodoro_start.wav"
  defp sound_name(:timer_finished), do: "timer_finished.wav"
  defp sound_name(:rest_start), do: "rest_start.wav"
  defp sound_name(:limbo_finished), do: "limbo_finished.wav"
  defp sound_name(:resting_finished), do: "resting_finished.wav"
  defp sound_name(:reset), do: "reset.wav"

  def play(name) do
    sound_path = get_sound(name) || get_sound(:default)

    if sound_path do
      play_sound(sound_path)
    end
  end

  def play_sound(sound_path) do
    Task.Supervisor.start_child(:pomodoro_task_supervisor, fn ->
      cond do
        System.find_executable("aplay") -> MuonTrap.cmd("aplay", ["--quiet", sound_path])
        System.find_executable("afplay") -> MuonTrap.cmd("afplay", [sound_path])
        true -> Logger.warn("aplay and afplay not found, skipping sound playback")
      end
    end)
  end

  # Default sound is in the priv directory
  def get_sound(:default),
    do: Path.join([:code.priv_dir(:pomodoro), "sounds", sound_name(:default)])

  def get_sound(name) do
    filename = sound_name(name)

    happy_with do
      {:ok, sound_dir} <- Application.fetch_env(:pomodoro, :sound_directory)
      path = Path.join([sound_dir, filename])
      true <- File.exists?(path)
      path
    else
      _ ->
        nil
    end
  end
end
