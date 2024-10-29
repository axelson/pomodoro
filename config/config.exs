import Config

config :logger, :console, format: "$time $metadata[$level] $message\n"

config :scenic, :assets, module: PomodoroUi.Assets

config :tzdata, :autoupdate, :disabled

config :launcher,
  scenes: [
    {"pomodoro", "Pomodoro", {PomodoroUi.Scene.Main, pomodoro_timer_pid: Pomodoro.PomodoroTimer}},
    {"pomodoro_mini", "Pomodoro Mini",
     {PomodoroUi.Scene.MiniComponent, t: {595, 69}, pomodoro_timer_pid: Pomodoro.PomodoroTimer}}
  ],
  auto_refresh: true

config :pomodoro, ecto_repos: [Pomodoro.Repo]

config :pomodoro, sound_directory: "priv/sounds"

config :pomodoro, Pomodoro.Repo,
  database: "priv/database.db",
  migration_primary_key: [type: :binary_id],
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 1

case Mix.env() do
  :dev ->
    config :pomodoro, :viewport,
      name: :main_viewport,
      size: {800, 480},
      default_scene: {PomodoroUi.Scene.Main, []},
      # default_scene:
      #   {PomodoroUi.Scene.MiniComponent, t: {595, 69}, pomodoro_timer_pid: Pomodoro.PomodoroTimer},
      drivers: [
        [
          module: Scenic.Driver.Local,
          window: [
            title: "Pomodoro Timer"
          ],
          on_close: :stop_system
        ]
      ]

    config :exsync,
      reload_timeout: 50,
      reload_callback: {ScenicLiveReload, :reload_current_scene, []}

  _ ->
    nil
end
