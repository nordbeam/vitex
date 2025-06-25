defmodule Mix.Tasks.Vitex do
  @moduledoc """
  Invokes Vite with the given args.

  Usage:

      $ mix vitex COMMAND ARGS

  Examples:

      $ mix vitex build
      $ mix vitex dev
      $ mix vitex preview

  """
  @shortdoc "Invokes Vite with the given args"

  use Mix.Task

  @impl true
  def run(args) do
    npm_path =
      find_executable("npm") || find_executable("bun") || find_executable("pnpm") ||
        find_executable("yarn")

    unless npm_path do
      raise "No package manager found. Please install npm, bun, pnpm, or yarn."
    end

    # Change to assets directory
    assets_dir = Path.join(File.cwd!(), "assets")

    unless File.exists?(assets_dir) do
      raise "Assets directory not found at #{assets_dir}"
    end

    # Run vite command
    cmd_args =
      if npm_path =~ "bun" do
        ["x", "--bun", "vite"] ++ args
      else
        ["run", "vite"] ++ args
      end

    # Pass through important environment variables
    env = [
      {"NODE_ENV", node_env()},
      {"MIX_ENV", to_string(Mix.env())}
    ]

    # Pass through Phoenix-specific env vars if they exist
    env =
      env
      |> maybe_add_env("PHX_HOST")
      |> maybe_add_env("VITE_DEV_SERVER_KEY")
      |> maybe_add_env("VITE_DEV_SERVER_CERT")
      |> maybe_add_env("PHOENIX_DOCKER")
      |> maybe_add_env("DOCKER_ENV")
      |> maybe_add_env("VITE_PORT")
      |> maybe_add_env("PHOENIX_BYPASS_ENV_CHECK")
      |> maybe_add_env("CI")
      |> maybe_add_env("RELEASE_NAME")
      |> maybe_add_env("FLY_APP_NAME")
      |> maybe_add_env("GIGALIXIR_APP_NAME")
      |> maybe_add_env("HEROKU_APP_NAME")
      |> maybe_add_env("RENDER")
      |> maybe_add_env("RAILWAY_ENVIRONMENT")

    Mix.shell().cmd("cd #{assets_dir} && #{npm_path} #{Enum.join(cmd_args, " ")}",
      env: env
    )
  end

  defp find_executable(name) do
    System.find_executable(name)
  end

  defp node_env do
    if Mix.env() == :prod, do: "production", else: "development"
  end

  defp maybe_add_env(env, key) do
    case System.get_env(key) do
      nil -> env
      value -> env ++ [{key, value}]
    end
  end
end

defmodule Mix.Tasks.Vitex.Build do
  @moduledoc """
  Builds assets via Vite.

  Usage:

      $ mix vite.build

  The task will install dependencies if needed and then run the build.
  """
  @shortdoc "Builds assets via Vite"

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Tasks.Vitex.Deps.run([])
    Mix.Tasks.Vitex.run(["build"])
  end
end

defmodule Mix.Tasks.Vitex.Deps do
  @moduledoc """
  Installs JavaScript dependencies.

  Usage:

      $ mix vite.deps

  """
  @shortdoc "Installs JavaScript dependencies"

  use Mix.Task

  @impl true
  def run(_args) do
    npm_path =
      find_executable("npm") || find_executable("bun") || find_executable("pnpm") ||
        find_executable("yarn")

    unless npm_path do
      raise "No package manager found. Please install npm, bun, pnpm, or yarn."
    end

    assets_dir = Path.join(File.cwd!(), "assets")

    unless File.exists?(assets_dir) do
      raise "Assets directory not found at #{assets_dir}"
    end

    install_cmd =
      cond do
        npm_path =~ "yarn" -> "install"
        npm_path =~ "bun" -> "install"
        npm_path =~ "pnpm" -> "install"
        true -> "ci --progress=false --no-audit --loglevel=error"
      end

    Mix.shell().cmd("cd #{assets_dir} && #{npm_path} #{install_cmd}")
  end

  defp find_executable(name) do
    System.find_executable(name)
  end
end
