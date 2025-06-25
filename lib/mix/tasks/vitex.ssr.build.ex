defmodule Mix.Tasks.Vitex.Ssr.Build do
  @moduledoc """
  Builds Server-Side Rendering (SSR) assets via Vite.

  This task is a convenience wrapper for building SSR assets.
  It runs `vite build --ssr` with the appropriate environment.

  ## Usage

      $ mix vitex.ssr.build

  The task will install dependencies if needed and then run the SSR build.

  ## Configuration

  Ensure your vite.config.js has SSR configuration:

      phoenix({
        input: 'js/app.js',
        ssr: 'js/ssr.js',
        ssrOutputDirectory: '../priv/ssr',
        // ... other options
      })
  """
  @shortdoc "Builds SSR assets via Vite"

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Tasks.Vitex.Install.run([])
    Mix.Tasks.Vitex.run(["build", "--ssr"])
  end
end
