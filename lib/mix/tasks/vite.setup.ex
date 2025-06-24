defmodule Mix.Tasks.Vite.Setup do
  @moduledoc """
  Set up Phoenix Vite in your project.

  This task will:
  1. Create vite.config.js if it doesn't exist
  2. Update package.json to reference the Vite plugin from deps
  3. Add necessary scripts to package.json

  ## Usage

      mix vite.setup
  """

  use Mix.Task

  @shortdoc "Set up Phoenix Vite in your project"

  def run(args) do
    Mix.shell().info("Setting up Phoenix Vite...")

    # Get the plugin path from the dependency
    plugin_path = PhoenixVite.plugin_path()

    # Create vite.config.js if it doesn't exist
    create_vite_config()

    # Update package.json
    update_package_json(plugin_path)

    # Offer to update dev.exs if --update-config flag is passed
    if "--update-config" in args do
      update_dev_config()
    end

    Mix.shell().info("""

    Phoenix Vite setup complete!

    Next steps:
    1. Run `cd assets && npm install` to install dependencies
    2. Update your config/dev.exs to use Vite as a watcher:

       watchers: [
         node: ["node_modules/.bin/vite", cd: Path.expand("../assets", __DIR__)]
       ]

    3. Update your root layout template:

       <%= PhoenixVite.vite_client() %>
       <%= PhoenixVite.vite_assets("css/app.css") %>
       ...
       <%= PhoenixVite.vite_assets("js/app.js") %>

    4. Run `mix phx.server` to start development

    Tip: Run `mix vite.setup --update-config` to automatically update your dev.exs
    """)
  end

  defp create_vite_config do
    config_path = "assets/vite.config.js"

    unless File.exists?(config_path) do
      # Check if Tailwind is being used
      has_tailwind =
        File.exists?("assets/css/app.css") &&
          File.read!("assets/css/app.css") |> String.contains?("@import \"tailwindcss\"")

      # Check if daisyUI is being used
      has_daisyui = detect_daisyui()

      # Build config based on what's available
      tailwind_import =
        if has_tailwind, do: "\nimport tailwindcss from '@tailwindcss/vite'", else: ""

      tailwind_plugin = if has_tailwind, do: "\n    tailwindcss(),", else: ""

      config_content = """
      import { defineConfig } from 'vite'
      import phoenix from '../deps/phoenix_vite/priv/static/phoenix_vite'#{tailwind_import}

      export default defineConfig({
        plugins: [#{tailwind_plugin}
          phoenix({
            input: ['js/app.js', 'css/app.css'],
            publicDirectory: '../priv/static',
            buildDirectory: 'assets',
            hotFile: '../priv/hot',
            manifestPath: '../priv/static/assets/manifest.json',
          })
        ],
      })
      """

      File.write!(config_path, config_content)
      Mix.shell().info("Created assets/vite.config.js")

      if has_tailwind do
        Mix.shell().info("Detected Tailwind CSS - added @tailwindcss/vite plugin")
      end

      if has_daisyui do
        Mix.shell().info("Detected daisyUI - will be configured in package.json")
      end
    else
      Mix.shell().info("assets/vite.config.js already exists, skipping...")
    end
  end

  defp update_package_json(_plugin_path) do
    package_json_path = "assets/package.json"

    # Check if Tailwind is being used
    has_tailwind =
      File.exists?("assets/css/app.css") &&
        File.read!("assets/css/app.css") |> String.contains?("@import \"tailwindcss\"")

    # Check if daisyUI is being used
    has_daisyui = detect_daisyui()

    # Check if topbar is being used
    has_topbar = detect_topbar()

    # Read existing package.json or create default content
    package_json =
      if File.exists?(package_json_path) do
        File.read!(package_json_path)
        |> Jason.decode!()
      else
        %{
          "name" => Path.basename(File.cwd!()),
          "version" => "0.0.0",
          "private" => true
        }
      end

    # Update dependencies
    dependencies =
      Map.get(package_json, "dependencies", %{})
      |> Map.put("vite", "^6.3.0")
      |> then(fn deps ->
        deps =
          if has_tailwind do
            deps
            |> Map.put("@tailwindcss/vite", "^4.1.0")
            |> Map.put("tailwindcss", "^4.1.0")
          else
            deps
          end

        deps =
          if has_daisyui do
            Map.put(deps, "daisyui", "latest")
          else
            deps
          end

        if has_topbar do
          Map.put(deps, "topbar", "^3.0.0")
        else
          deps
        end
      end)

    dev_dependencies =
      Map.get(package_json, "devDependencies", %{})
      |> Map.put("@types/phoenix", "^1.6.0")

    # Update scripts
    scripts =
      Map.get(package_json, "scripts", %{})
      |> Map.put("dev", "vite")
      |> Map.put("build", "vite build")

    # Update package.json
    updated_package_json =
      package_json
      # Add ESM type
      |> Map.put("type", "module")
      |> Map.put("dependencies", dependencies)
      |> Map.put("devDependencies", dev_dependencies)
      |> Map.put("scripts", scripts)

    # Write back
    File.write!(package_json_path, Jason.encode!(updated_package_json, pretty: true))
    Mix.shell().info("Updated package.json")

    if has_tailwind do
      Mix.shell().info("Added Tailwind CSS v4 dependencies")
    end

    if has_daisyui do
      Mix.shell().info("Added daisyUI to dependencies")
      update_css_for_npm_daisyui()
      remove_vendored_daisyui()
    end

    if has_topbar do
      Mix.shell().info("Added topbar to dependencies")
      update_js_for_npm_topbar()
      remove_vendored_topbar()
    end
  end

  defp update_dev_config do
    config_path = "config/dev.exs"

    if File.exists?(config_path) do
      config_content = File.read!(config_path)

      # Check if watchers already contains vite
      if String.contains?(config_content, "vite") do
        Mix.shell().info("Vite watcher already configured in config/dev.exs")
      else
        # Try to replace the watchers section
        updated_content =
          if String.contains?(config_content, "watchers: [") do
            # Replace existing watchers
            String.replace(
              config_content,
              ~r/watchers:\s*\[[^\]]*\]/s,
              "watchers: [\n    node: [\"node_modules/.bin/vite\", cd: Path.expand(\"../assets\", __DIR__)]\n  ]"
            )
          else
            # Add watchers to endpoint config
            String.replace(
              config_content,
              ~r/(config\s+:[\w_]+,\s+[\w_]+\.Endpoint,[^}]+)([\s\S]*?)((?=\n\nconfig|\z))/,
              "\\1\\2,\n  watchers: [\n    node: [\"node_modules/.bin/vite\", cd: Path.expand(\"../assets\", __DIR__)]\n  ]\\3"
            )
          end

        if updated_content != config_content do
          File.write!(config_path, updated_content)
          Mix.shell().info("Updated config/dev.exs with Vite watcher")
        else
          Mix.shell().info(
            "Could not automatically update config/dev.exs - please update manually"
          )
        end
      end
    else
      Mix.shell().info("config/dev.exs not found")
    end
  end

  defp detect_daisyui do
    app_css_path = "assets/css/app.css"

    # First check if app.css exists and contains daisyUI references
    has_daisyui_in_css =
      File.exists?(app_css_path) &&
        File.read!(app_css_path) |> String.contains?("daisyui")

    # Check for vendored daisyUI files
    has_vendored_daisyui =
      File.exists?("assets/vendor/daisyui.js") ||
        File.exists?("assets/vendor/daisyui-theme.js")

    # Check package.json for existing daisyUI dependency
    package_json_path = "assets/package.json"

    has_daisyui_in_package =
      if File.exists?(package_json_path) do
        case File.read!(package_json_path) |> Jason.decode() do
          {:ok, package} ->
            deps = Map.get(package, "dependencies", %{})
            Map.has_key?(deps, "daisyui")

          _ ->
            false
        end
      else
        false
      end

    has_daisyui_in_css || has_vendored_daisyui || has_daisyui_in_package
  end

  defp update_css_for_npm_daisyui do
    app_css_path = "assets/css/app.css"

    if File.exists?(app_css_path) do
      content = File.read!(app_css_path)

      # Replace vendored daisyUI imports with npm version
      updated_content =
        content
        |> String.replace(~r/@plugin\s+"\.\.\/vendor\/daisyui"/, "@plugin \"daisyui\"")
        |> String.replace(~r/@plugin\s+"\.\.\/vendor\/daisyui-theme"/, "@plugin \"daisyui/theme\"")
        |> String.replace(~r/@plugin\s+'\.\.\/vendor\/daisyui'/, "@plugin \"daisyui\"")
        |> String.replace(~r/@plugin\s+'\.\.\/vendor\/daisyui-theme'/, "@plugin \"daisyui/theme\"")

      if updated_content != content do
        File.write!(app_css_path, updated_content)
        Mix.shell().info("Updated app.css to use daisyUI from npm")
      end
    end
  end

  defp remove_vendored_daisyui do
    vendored_files = [
      "assets/vendor/daisyui.js",
      "assets/vendor/daisyui-theme.js"
    ]

    Enum.each(vendored_files, fn file ->
      if File.exists?(file) do
        File.rm!(file)
        Mix.shell().info("Removed vendored file: #{file}")
      end
    end)

    # Check if vendor directory is empty and remove it
    vendor_dir = "assets/vendor"

    if File.exists?(vendor_dir) && File.ls!(vendor_dir) == [] do
      File.rmdir!(vendor_dir)
      Mix.shell().info("Removed empty vendor directory")
    end
  end

  defp detect_topbar do
    app_js_path = "assets/js/app.js"

    # Check if app.js exists and imports topbar from vendor
    has_topbar_import =
      File.exists?(app_js_path) &&
        File.read!(app_js_path) |> String.contains?("../vendor/topbar")

    # Check for vendored topbar file
    has_vendored_topbar = File.exists?("assets/vendor/topbar.js")

    # Check package.json for existing topbar dependency
    package_json_path = "assets/package.json"

    has_topbar_in_package =
      if File.exists?(package_json_path) do
        case File.read!(package_json_path) |> Jason.decode() do
          {:ok, package} ->
            deps = Map.get(package, "dependencies", %{})
            Map.has_key?(deps, "topbar")

          _ ->
            false
        end
      else
        false
      end

    has_topbar_import || has_vendored_topbar || has_topbar_in_package
  end

  defp update_js_for_npm_topbar do
    app_js_path = "assets/js/app.js"

    if File.exists?(app_js_path) do
      content = File.read!(app_js_path)

      # Replace vendored topbar import with npm version
      updated_content =
        content
        |> String.replace(~r/import\s+topbar\s+from\s+"\.\.\/vendor\/topbar"/, "import topbar from \"topbar\"")
        |> String.replace(~r/import\s+topbar\s+from\s+'\.\.\/vendor\/topbar'/, "import topbar from \"topbar\"")

      if updated_content != content do
        File.write!(app_js_path, updated_content)
        Mix.shell().info("Updated app.js to use topbar from npm")
      end
    end
  end

  defp remove_vendored_topbar do
    vendored_file = "assets/vendor/topbar.js"

    if File.exists?(vendored_file) do
      File.rm!(vendored_file)
      Mix.shell().info("Removed vendored file: #{vendored_file}")
    end

    # Check if vendor directory is empty and remove it
    vendor_dir = "assets/vendor"

    if File.exists?(vendor_dir) && File.ls!(vendor_dir) == [] do
      File.rmdir!(vendor_dir)
      Mix.shell().info("Removed empty vendor directory")
    end
  end
end
