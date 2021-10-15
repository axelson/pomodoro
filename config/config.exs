# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, :console, format: "$time $metadata[$level] $message\n"

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
    config :exsync,
      reload_timeout: 50,
      reload_callback: {ScenicLiveReload, :reload_current_scene, []}

  _ ->
    nil
end

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :pomodoro, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:pomodoro, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"
