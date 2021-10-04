defmodule Pomodoro.SoundPlayer do
  defp sound_name(:default), do: "default.wav"
  defp sound_name(:pomodoro_start), do: "pomodoro_start.wav"
  defp sound_name(:timer_finished), do: "timer_finished.wav"
  defp sound_name(:rest_start), do: "rest_start.wav"
  defp sound_name(:limbo_finished), do: "limbo_finished.wav"
  defp sound_name(:resting_finished), do: "resting_finished.wav"

  def play(name) do
    sound_path = get_sound(name) || get_sound(:default)

    Task.Supervisor.start_child(:pomodoro_task_supervisor, fn ->
      MuonTrap.cmd("aplay", ["--quiet", sound_path])
    end)
  end

  # Default sound is in the priv directory
  def get_sound(:default), do:
    Path.join([:code.priv_dir(:pomodoro), "sounds", sound_name(:default)])

  def get_sound(name) do
    filename = sound_name(name)
    path = Path.join([Application.get_env(:pomodoro, :sound_directory), filename])

    if File.exists?(path) do
      path
    end
  end
end
