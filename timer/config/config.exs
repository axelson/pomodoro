# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configure the main viewport for the Scenic application
config :timer_ui, :viewport, %{
  name: :main_viewport,
  size: {700, 600},
  default_scene: {Timer.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "timer_ui"]
    }
  ]
}

case Mix.env() do
  :dev ->
    config :exsync,
      reload_timeout: 75,
      reload_callback: {ScenicLiveReload, :reload_current_scene, []}

  _ -> nil
end
