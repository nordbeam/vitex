defmodule Mix.Tasks.Vitex.Install.BunIntegration do
  @moduledoc """
  Handles the special integration with the Elixir bun package.

  This is different from system package managers because:
  - Bun is managed by Mix (not system-installed)
  - The bun executable is auto-downloaded to _build/bun
  - It can use Bun workspaces for Phoenix JS dependencies
  - Mix tasks handle the bun installation lifecycle

  The Elixir bun package is similar to how Phoenix manages esbuild and tailwind,
  providing a controlled, versioned JavaScript runtime within the Elixir ecosystem.
  """

  @doc """
  Integrates Bun into the project when --bun flag is specified.

  This performs all Bun-specific setup in a coordinated way:
  1. Adds the bun Mix dependency
  2. Configures bun version and assets profile
  3. Sets up Bun-specific mix aliases
  4. Configures the development watcher to use _build/bun
  5. Updates package.json to use Bun workspaces
  6. Adds helpful notice about Bun configuration
  """
  def integrate(igniter) do
    if should_integrate?(igniter) do
      igniter
      |> add_dependency()
      |> configure_bun_version()
      |> setup_mix_aliases()
      |> setup_watcher()
      |> setup_workspaces()
      |> add_notice()
      |> validate_setup()
    else
      igniter
    end
  end

  @doc """
  Checks if Bun integration should be performed.
  """
  def should_integrate?(igniter) do
    igniter.args.options[:bun] || false
  end

  @doc """
  Checks if the project is using Bun integration.
  """
  def using_bun?(igniter) do
    should_integrate?(igniter)
  end

  @doc """
  Returns the Bun-specific configuration for various operations.
  """
  def config do
    %{
      executable: "_build/bun",
      install_cmd: "bun install --cwd assets",
      run_cmd: "_build/bun run",
      uses_workspaces: true,
      requires_dep: {:bun, "~> 1.5", runtime: Mix.env() == :dev}
    }
  end

  # Private functions

  defp add_dependency(igniter) do
    {name, version, opts} = config().requires_dep
    Igniter.Project.Deps.add_dep(igniter, {name, version, opts})
  end

  defp configure_bun_version(igniter) do
    igniter
    |> Igniter.Project.Config.configure(
      "config.exs",
      :bun,
      [:version],
      "1.1.22"
    )
    |> Igniter.Project.Config.configure(
      "config.exs",
      :bun,
      [:assets],
      {:code,
       quote do
         [
           args: ["install"],
           cd: Path.expand("../assets", __DIR__)
         ]
       end}
    )
  end

  defp setup_mix_aliases(igniter) do
    igniter
    |> Igniter.Project.TaskAliases.modify_existing_alias("assets.setup", fn zipper ->
      {:ok,
       Sourceror.Zipper.replace(
         zipper,
         quote(
           do: [
             "vitex.install --if-missing",
             "bun.install --if-missing",
             "bun assets"
           ]
         )
       )}
    end)
    |> Igniter.Project.TaskAliases.modify_existing_alias("assets.build", fn zipper ->
      {:ok,
       Sourceror.Zipper.replace(
         zipper,
         quote(do: ["bun assets", "cmd _build/bun run build --prefix assets"])
       )}
    end)
    |> Igniter.Project.TaskAliases.modify_existing_alias("assets.deploy", fn zipper ->
      {:ok,
       Sourceror.Zipper.replace(
         zipper,
         quote(do: ["bun assets", "cmd _build/bun run build --prefix assets", "phx.digest"])
       )}
    end)
  end

  defp setup_watcher(igniter) do
    {igniter, endpoint} = Igniter.Libs.Phoenix.select_endpoint(igniter)
    app_name = Igniter.Project.Application.app_name(igniter)

    watcher_value =
      {:code,
       Sourceror.parse_string!("""
       ["_build/bun", "run", "dev", cd: Path.expand("../assets", __DIR__)]
       """)}

    Igniter.Project.Config.configure(
      igniter,
      "dev.exs",
      app_name,
      [endpoint, :watchers, :bun],
      watcher_value
    )
  end

  defp setup_workspaces(igniter) do
    # This is handled in the main installer's update_package_json
    # but we mark it here for clarity
    Igniter.assign(igniter, :bun_workspaces_needed, true)
  end

  defp add_notice(igniter) do
    notice = """
    Bun Configuration:
    - Bun is configured as your package manager and JavaScript runtime
    - The bun executable will be auto-downloaded to _build/bun
    - Phoenix JS dependencies are managed via Bun workspaces
    - Your dev watcher uses bun to run Vite: `_build/bun run dev`
    - Assets are built with: `mix bun assets` then `_build/bun run build`
    - To install dependencies manually: `mix bun assets`
    """

    Igniter.add_notice(igniter, notice)
  end

  defp validate_setup(igniter) do
    # Check if the bun package will be available
    cond do
      # If we're in a test environment, skip validation
      Map.get(igniter, :test_mode, false) ->
        igniter

      # Check if Mix.Tasks.Bun is already loaded
      Code.ensure_loaded?(Mix.Tasks.Bun) ->
        igniter

      # Otherwise add a notice about running mix deps.get
      true ->
        Igniter.add_notice(
          igniter,
          """
          Important: After running this installer, you need to run:
            mix deps.get

          This will install the Bun package and make the bun executable available.
          """
        )
    end
  end

  @doc """
  Returns the command to run for package installation based on whether Bun is being used.
  """
  def install_command(igniter) do
    if using_bun?(igniter) do
      # Bun package handles its own installation via mix task
      nil
    else
      # Detect system package manager
      npm_path =
        System.find_executable("npm") || System.find_executable("bun") ||
          System.find_executable("pnpm") || System.find_executable("yarn") ||
          raise "No package manager found. Please install npm, bun, pnpm, or yarn."

      cond do
        npm_path =~ "bun" -> "bun install --cwd assets"
        npm_path =~ "pnpm" -> "pnpm install --prefix assets"
        npm_path =~ "yarn" -> "cd assets && yarn install"
        true -> "npm install --prefix assets"
      end
    end
  end

  @doc """
  Updates package.json to include Bun workspaces configuration.
  """
  def update_package_json(package_json, igniter) do
    if using_bun?(igniter) || igniter.assigns[:bun_workspaces_needed] do
      package_json
      |> Map.put("workspaces", ["../deps/*"])
      |> Map.update!("dependencies", fn deps ->
        Map.merge(deps, %{
          "phoenix" => "workspace:*",
          "phoenix_html" => "workspace:*",
          "phoenix_live_view" => "workspace:*"
        })
      end)
    else
      package_json
    end
  end
end
