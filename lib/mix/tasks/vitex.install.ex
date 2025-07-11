if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Vitex.Install do
    @moduledoc """
    Installs and configures Phoenix Vite in a Phoenix application using Igniter.

    This installer:
    1. Creates vite.config.js with appropriate configuration
    2. Updates package.json with Vite dependencies and scripts
    3. Adds the Vite watcher to the development configuration
    4. Updates the root layout template to use Vite helpers
    5. Creates or updates asset files for Vite

    ## Usage

        $ mix vitex.install

    ## Options

        --ssr                Enable Server-Side Rendering support
        --tls                Enable automatic TLS certificate detection
        --react              Enable React Fast Refresh support
        --typescript         Enable TypeScript support
        --inertia            Enable Inertia.js support (automatically enables React)
        --shadcn             Enable shadcn/ui component library (requires --typescript and either --react or --inertia)
        --base-color         Base color for shadcn/ui theme (neutral,gray, zinc, stone, slate) - defaults to neutral
        --bun                Use Bun as the package manager instead of npm
        --yes                Don't prompt for confirmations

    ## Package Manager Support

    Vitex supports two approaches for package management:

    1. **System Package Managers** (npm, pnpm, yarn): Uses whatever is installed on the system
    2. **Elixir-Managed Bun** (--bun flag): Uses the Elixir bun package to download and manage the bun executable

    The --bun option is special because:
    - It adds a Mix dependency for bun
    - The bun executable is managed at _build/bun
    - It can use Bun workspaces for Phoenix JS dependencies
    - Mix tasks handle the bun installation lifecycle
    """

    use Igniter.Mix.Task
    require Igniter.Code.Common

    alias Mix.Tasks.Vitex.Install.BunIntegration

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        schema: [
          ssr: :boolean,
          tls: :boolean,
          react: :boolean,
          typescript: :boolean,
          inertia: :boolean,
          camelize_props: :boolean,
          history_encrypt: :boolean,
          yes: :boolean,
          bun: :boolean,
          shadcn: :boolean,
          base_color: :string
        ],
        defaults: [],
        positional: [],
        composes: ["deps.get"]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # If inertia is enabled, also enable react
      igniter =
        if igniter.args.options[:inertia] do
          put_in(igniter.args.options[:react], true)
        else
          igniter
        end

      # Validate shadcn requirements
      igniter =
        if igniter.args.options[:shadcn] do
          cond do
            !igniter.args.options[:typescript] ->
              Igniter.add_issue(igniter, """
              The --shadcn flag requires TypeScript to be enabled.
              Please add the --typescript flag to use shadcn/ui.
              """)

            !(igniter.args.options[:react] || igniter.args.options[:inertia]) ->
              Igniter.add_issue(igniter, """
              The --shadcn flag requires either React or Inertia.js to be enabled.
              Please add either the --react or --inertia flag to use shadcn/ui.
              """)

            true ->
              igniter
          end
        else
          igniter
        end

      igniter
      |> maybe_add_inertia_dep()
      |> BunIntegration.integrate()
      |> setup_html_helpers()
      |> maybe_setup_inertia()
      |> create_vite_config()
      |> update_package_json()
      |> setup_watcher_for_system_package_managers()
      |> remove_old_watchers()
      |> update_root_layout()
      |> setup_assets()
      |> maybe_setup_shadcn()
      |> update_mix_aliases_for_system_package_managers()
      |> print_next_steps()
    end

    def maybe_add_inertia_dep(igniter) do
      if igniter.args.options[:inertia] do
        Igniter.Project.Deps.add_dep(igniter, {:inertia, "~> 2.4"})
      else
        igniter
      end
    end

    # Bun integration is now handled by BunIntegration.integrate/1

    # Test helpers - these delegate to the appropriate functions
    def update_mix_aliases(igniter) do
      if BunIntegration.using_bun?(igniter) do
        BunIntegration.integrate(igniter)
      else
        update_mix_aliases_for_system_package_managers(igniter)
      end
    end

    def setup_watcher(igniter) do
      if BunIntegration.using_bun?(igniter) do
        BunIntegration.integrate(igniter)
      else
        setup_watcher_for_system_package_managers(igniter)
      end
    end

    def maybe_add_bun_dep(igniter) do
      BunIntegration.integrate(igniter)
    end

    def maybe_setup_bun_config(igniter) do
      BunIntegration.integrate(igniter)
    end

    def setup_html_helpers(igniter) do
      update_web_ex_helper(igniter, :html, fn zipper ->
        import_code = """
            alias Vitex, as: Vite
        """

        with {:ok, zipper} <- move_to_last_import_or_alias(zipper) do
          {:ok, Igniter.Code.Common.add_code(zipper, import_code)}
        end
      end)
    end

    def maybe_setup_inertia(igniter) do
      if igniter.args.options[:inertia] do
        igniter
        |> setup_inertia_controller_helpers()
        |> setup_inertia_html_helpers()
        |> setup_inertia_router()
        |> add_inertia_config()
        |> setup_page_controller()
      else
        igniter
      end
    end

    defp setup_inertia_controller_helpers(igniter) do
      update_web_ex_helper(igniter, :controller, fn zipper ->
        import_code = "import Inertia.Controller"

        with {:ok, zipper} <- move_to_last_import_or_alias(zipper) do
          {:ok, Igniter.Code.Common.add_code(zipper, import_code)}
        end
      end)
    end

    defp setup_inertia_html_helpers(igniter) do
      update_web_ex_helper(igniter, :html, fn zipper ->
        import_code = """
            import Inertia.HTML
        """

        with {:ok, zipper} <- move_to_last_import_or_alias(zipper) do
          {:ok, Igniter.Code.Common.add_code(zipper, import_code)}
        end
      end)
    end

    defp setup_inertia_router(igniter) do
      igniter
      |> Igniter.Libs.Phoenix.append_to_pipeline(:browser, "plug Inertia.Plug")
      |> update_router_pipeline()
    end

    defp update_router_pipeline(igniter) do
      web_module = web_module_name(igniter)

      inertia_pipeline = """
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {#{web_module}.Layouts, :inertia_root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug Inertia.Plug
      """

      igniter
      |> Igniter.Libs.Phoenix.add_pipeline(
        :inertia,
        inertia_pipeline,
        arg2: web_module
      )
      |> Igniter.Libs.Phoenix.add_scope(
        "/inertia",
        """
        pipe_through :inertia
        get "/", PageController, :inertia
        """,
        arg2: web_module
      )
    end

    defp web_module_name(igniter) do
      Igniter.Libs.Phoenix.web_module(igniter)
    end

    defp setup_page_controller(igniter) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      controller_module = Module.concat([web_module, PageController])

      # Check if the PageController already exists
      case Igniter.Project.Module.find_module(igniter, controller_module) do
        {:ok, {igniter, _source, _zipper}} ->
          # Controller exists, add the inertia function to it
          igniter
          |> Igniter.Project.Module.find_and_update_module!(controller_module, fn zipper ->
            # Check if the inertia function already exists
            case Igniter.Code.Function.move_to_def(zipper, :inertia, 2) do
              {:ok, _zipper} ->
                # Function already exists, don't modify
                {:ok, zipper}

              :error ->
                # Function doesn't exist, add it
                inertia_function = """

                def inertia(conn, _params) do
                  conn
                  |> assign_prop(:greeting, "Hello from Inertia.js and Phoenix!")
                  |> render_inertia("Home")
                end
                """

                # Try to add the function after the last def in the module
                case Igniter.Code.Common.move_to_last(zipper, fn zipper ->
                       node = Sourceror.Zipper.node(zipper)
                       match?({:def, _, _}, node) or match?({:defp, _, _}, node)
                     end) do
                  {:ok, zipper} ->
                    case Igniter.Code.Common.add_code(zipper, inertia_function) do
                      {:ok, updated_zipper} -> {:ok, updated_zipper}
                      updated_zipper -> {:ok, updated_zipper}
                    end

                  :error ->
                    # If no defs found, return unchanged
                    {:ok, zipper}
                end
            end
          end)
          |> Igniter.add_notice("""
          Added inertia action to existing PageController.

          The action renders the Home component with a greeting prop.
          """)

        {:error, igniter} ->
          # Controller doesn't exist, create it
          controller_path =
            controller_module
            |> inspect()
            |> String.replace(".", "/")
            |> Macro.underscore()
            |> then(&"lib/#{&1}.ex")

          controller_content = """
          defmodule #{inspect(controller_module)} do
            use #{inspect(web_module)}, :controller

            def inertia(conn, _params) do
              conn
              |> assign_prop(:greeting, "Hello from Inertia.js and Phoenix!")
              |> render_inertia("Home")
            end
          end
          """

          igniter
          |> Igniter.create_new_file(controller_path, controller_content)
          |> Igniter.add_notice("""
          Created PageController with Inertia action at #{controller_path}

          The controller renders the Home component with a greeting prop.
          """)
      end
    end

    defp add_inertia_config(igniter) do
      {igniter, endpoint_module} = Igniter.Libs.Phoenix.select_endpoint(igniter)

      # Determine configuration based on options
      camelize_props = igniter.args.options[:camelize_props] || false
      history_encryption = igniter.args.options[:history_encrypt] || false

      config_options = [
        endpoint: endpoint_module
      ]

      # Add camelize_props config if specified
      config_options =
        if camelize_props do
          Keyword.put(config_options, :camelize_props, true)
        else
          config_options
        end

      # Add history encryption config if specified
      config_options =
        if history_encryption do
          Keyword.put(config_options, :history, encrypt: true)
        else
          config_options
        end

      # Add the configuration to config.exs
      Enum.reduce(config_options, igniter, fn {key, value}, igniter ->
        Igniter.Project.Config.configure(
          igniter,
          "config.exs",
          :inertia,
          [key],
          value
        )
      end)
    end

    # Run an update function within the quote do ... end block inside a *web.ex helper function
    defp update_web_ex_helper(igniter, helper_name, update_fun) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)

      case Igniter.Project.Module.find_module(igniter, web_module) do
        {:ok, {igniter, _source, _zipper}} ->
          Igniter.Project.Module.find_and_update_module!(igniter, web_module, fn zipper ->
            with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, helper_name, 0),
                 {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
              Igniter.Code.Common.within(zipper, update_fun)
            else
              :error ->
                {:warning, "Could not find #{helper_name}/0 function in #{inspect(web_module)}"}
            end
          end)

        {:error, igniter} ->
          Igniter.add_warning(
            igniter,
            "Could not find web module #{inspect(web_module)}. You may need to manually add Vitex helpers."
          )
      end
    end

    defp move_to_last_import_or_alias(zipper) do
      # Try to find the last import first
      case Igniter.Code.Common.move_to_last(
             zipper,
             &Igniter.Code.Function.function_call?(&1, :import)
           ) do
        {:ok, zipper} ->
          {:ok, zipper}

        _ ->
          # If no imports, try to find the last alias
          Igniter.Code.Common.move_to_last(
            zipper,
            &Igniter.Code.Function.function_call?(&1, :alias)
          )
      end
    end

    # Common detection helpers
    defp detect_tailwind(igniter) do
      css_path = "assets/css/app.css"

      if Igniter.exists?(igniter, css_path) do
        updated_igniter = Igniter.include_existing_file(igniter, css_path)

        source = Rewrite.source!(updated_igniter.rewrite, css_path)
        content = Rewrite.Source.get(source, :content)
        has_tailwind = String.contains?(content, "@import \"tailwindcss\"")
        {updated_igniter, has_tailwind}
      else
        {igniter, false}
      end
    end

    def create_vite_config(igniter) do
      {igniter, has_tailwind} = detect_tailwind(igniter)

      config = build_vite_config(igniter.args.options, has_tailwind)

      Igniter.create_new_file(igniter, "assets/vite.config.js", config, on_exists: :skip)
    end

    defp build_vite_config(options, has_tailwind) do
      imports = build_vite_imports(options, has_tailwind)
      plugins = build_vite_plugins(options, has_tailwind)
      input_files = build_input_files(options)
      additional_opts = build_additional_options(options)
      path_import = if options[:shadcn], do: "\nimport path from 'path'", else: ""

      """
      import { defineConfig } from 'vite'
      import phoenix from '../deps/vitex/priv/static/vitex'#{path_import}#{imports}

      export default defineConfig({
        plugins: [#{plugins}
          phoenix({
            input: #{input_files},
            publicDirectory: '../priv/static',
            buildDirectory: 'assets',
            hotFile: '../priv/hot',
            manifestPath: '../priv/static/assets/manifest.json',#{additional_opts}
          })
        ],#{build_resolve_config(options)}
      })
      """
    end

    defp build_vite_imports(options, has_tailwind) do
      imports = []

      imports =
        if options[:react],
          do: imports ++ ["\nimport react from '@vitejs/plugin-react'"],
          else: imports

      imports =
        if has_tailwind,
          do: imports ++ ["\nimport tailwindcss from '@tailwindcss/vite'"],
          else: imports

      Enum.join(imports)
    end

    defp build_vite_plugins(options, has_tailwind) do
      plugins = []

      plugins = if options[:react], do: plugins ++ ["\n    react(),"], else: plugins
      plugins = if has_tailwind, do: plugins ++ ["\n    tailwindcss(),"], else: plugins

      Enum.join(plugins)
    end

    defp build_input_files(options) do
      typescript = options[:typescript] || false
      inertia = options[:inertia] || false

      entry_extension = determine_entry_extension(typescript, inertia)

      if inertia && typescript do
        "['js/app.tsx', 'js/app.ts', 'css/app.css']"
      else
        "['js/app.#{entry_extension}', 'css/app.css']"
      end
    end

    defp determine_entry_extension(typescript, inertia) do
      cond do
        inertia && typescript -> "tsx"
        inertia -> "jsx"
        typescript -> "ts"
        true -> "js"
      end
    end

    defp determine_app_extension(typescript, _react, _inertia) do
      # For root.html.heex, we always use app.js or app.ts
      # The JSX/TSX files are separate entry points for React/Inertia
      if typescript, do: "ts", else: "js"
    end

    defp build_additional_options(options) do
      config_items = []
      config_items = maybe_add_config(config_items, "refresh: true", true)

      config_items =
        maybe_add_config(
          config_items,
          "reactRefresh: true",
          !!(options[:react] || options[:inertia])
        )

      config_items = maybe_add_config(config_items, "detectTls: true", !!options[:tls])
      config_items = maybe_add_config(config_items, "ssr: 'js/ssr.js'", !!options[:ssr])

      case config_items do
        [] -> ""
        items -> "\n" <> Enum.map_join(items, "\n", &"            #{&1},")
      end
    end

    defp build_resolve_config(options) do
      cond do
        options[:shadcn] ->
          """
          resolve: {
            alias: {
              "@": path.resolve(__dirname, "./js")
            }
          }
          """

        options[:typescript] ->
          """
            resolve: {
              alias: {
                '@': '/js'
              }
            }
          """

        true ->
          ""
      end
    end

    defp maybe_add_config(configs, _config, false), do: configs
    defp maybe_add_config(configs, config, true), do: [config | configs]

    def update_package_json(igniter) do
      igniter
      |> detect_project_features()
      |> build_and_write_package_json()
      |> update_vendor_imports()
      |> queue_npm_install()
    end

    defp detect_project_features(igniter) do
      {igniter, has_tailwind} = detect_tailwind(igniter)
      {igniter, has_topbar} = detect_topbar(igniter)
      {igniter, has_daisyui} = detect_daisyui(igniter)

      features = %{
        react: igniter.args.options[:react] || false,
        typescript: igniter.args.options[:typescript] || false,
        inertia: igniter.args.options[:inertia] || false,
        shadcn: igniter.args.options[:shadcn] || false,
        tailwind: has_tailwind,
        topbar: has_topbar,
        daisyui: has_daisyui
      }

      Igniter.assign(igniter, :detected_features, features)
    end

    defp build_and_write_package_json(igniter) do
      features = igniter.assigns[:detected_features]

      dependencies = build_dependencies(features)
      dev_dependencies = build_dev_dependencies(features)

      package_json = %{
        "name" => Igniter.Project.Application.app_name(igniter) |> to_string(),
        "version" => "0.0.0",
        "type" => "module",
        "private" => true,
        "dependencies" => dependencies,
        "devDependencies" => dev_dependencies,
        "scripts" => %{
          "dev" => "vite",
          "build" => "vite build"
        }
      }

      # Add Bun workspaces for Phoenix JS libraries if needed
      package_json = BunIntegration.update_package_json(package_json, igniter)

      content = Jason.encode!(package_json, pretty: true)

      Igniter.create_new_file(igniter, "assets/package.json", content, on_exists: :skip)
    end

    defp build_dependencies(features) do
      deps = %{"vite" => "^7.0.0"}

      deps = if features.topbar, do: Map.put(deps, "topbar", "^3.0.0"), else: deps

      deps =
        if features.tailwind do
          Map.merge(deps, %{
            "@tailwindcss/vite" => "^4.1.0",
            "tailwindcss" => "^4.1.0"
          })
        else
          deps
        end

      deps = if features.daisyui, do: Map.put(deps, "daisyui", "latest"), else: deps

      deps =
        if features.react do
          Map.merge(deps, %{
            "react" => "^19.1.0",
            "react-dom" => "^19.1.0",
            "@vitejs/plugin-react" => "^4.3.4"
          })
        else
          deps
        end

      if features.inertia do
        Map.merge(deps, %{
          "@inertiajs/react" => "^2.0",
          "axios" => "^1.6.0"
        })
      else
        deps
      end
    end

    defp build_dev_dependencies(features) do
      dev_deps = %{"@types/phoenix" => "^1.6.0"}

      dev_deps =
        if features.typescript do
          Map.put(dev_deps, "typescript", "^5.7.2")
        else
          dev_deps
        end

      if features.react && features.typescript do
        Map.merge(dev_deps, %{
          "@types/react" => "^19.1.0",
          "@types/react-dom" => "^19.1.0"
        })
      else
        dev_deps
      end
    end

    def update_vendor_imports(igniter) do
      features = igniter.assigns[:detected_features]

      igniter
      |> maybe_update_topbar_imports(features.topbar)
      |> maybe_update_daisyui_imports(features.daisyui)
    end

    defp maybe_update_topbar_imports(igniter, true) do
      igniter
      |> update_js_for_npm_topbar()
      |> remove_vendored_topbar()
    end

    defp maybe_update_topbar_imports(igniter, false), do: igniter

    defp maybe_update_daisyui_imports(igniter, true) do
      igniter
      |> update_css_for_npm_daisyui()
      |> remove_vendored_daisyui()
    end

    defp maybe_update_daisyui_imports(igniter, false), do: igniter

    defp queue_npm_install(igniter) do
      case BunIntegration.install_command(igniter) do
        nil ->
          # Bun handles its own installation
          igniter

        install_cmd ->
          Igniter.add_task(igniter, "cmd", [install_cmd])
      end
    end

    def setup_watcher_for_system_package_managers(igniter) do
      # Bun watcher is handled by BunIntegration
      if BunIntegration.using_bun?(igniter) do
        igniter
      else
        {igniter, endpoint} = Igniter.Libs.Phoenix.select_endpoint(igniter)

        # Use Vite directly with npm/yarn/pnpm
        watcher_value =
          {:code,
           Sourceror.parse_string!("""
           ["node_modules/.bin/vite", "dev", cd: Path.expand("../assets", __DIR__)]
           """)}

        Igniter.Project.Config.configure(
          igniter,
          "dev.exs",
          Igniter.Project.Application.app_name(igniter),
          [endpoint, :watchers, :node],
          watcher_value
        )
      end
    end

    def remove_old_watchers(igniter) do
      {igniter, endpoint} = Igniter.Libs.Phoenix.select_endpoint(igniter)
      app_name = Igniter.Project.Application.app_name(igniter)

      # We need to update the watchers configuration by removing specific keys
      Igniter.Project.Config.configure(
        igniter,
        "dev.exs",
        app_name,
        [endpoint, :watchers],
        {:code,
         quote do
           []
         end},
        updater: fn zipper ->
          # Remove esbuild and tailwind entries from the keyword list
          case Igniter.Code.Keyword.remove_keyword_key(zipper, :esbuild) do
            {:ok, zipper} ->
              case Igniter.Code.Keyword.remove_keyword_key(zipper, :tailwind) do
                {:ok, zipper} -> {:ok, zipper}
                :error -> {:ok, zipper}
              end

            :error ->
              {:ok, zipper}
          end
        end
      )
    end

    def update_root_layout(igniter) do
      file_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "components",
          "layouts",
          "root.html.heex"
        ])

      inertia = igniter.args.options[:inertia] || false
      react = igniter.args.options[:react] || false
      typescript = igniter.args.options[:typescript] || false

      # Determine the correct app file extension
      app_ext = determine_app_extension(typescript, react, inertia)

      # First update the regular root.html.heex regardless of inertia flag
      igniter =
        igniter
        |> Igniter.include_existing_file(file_path)
        |> Igniter.update_file(file_path, fn source ->
          Rewrite.Source.update(source, :content, fn
            content when is_binary(content) ->
              if String.contains?(content, "Vitex.vite_") or
                   String.contains?(content, "Vite.vite_") do
                # Already configured
                content
              else
                # Replace Phoenix asset helpers with Vite helpers
                updated =
                  content
                  # First, try to replace the combined CSS and JS pattern (common in phx.new projects)
                  |> String.replace(
                    ~r/(\s*)<link[^>]+href={~p"\/assets\/app\.css"}[^>]*>\s*\n\s*<script[^>]+src={~p"\/assets\/app\.js"}[^>]*>\s*\n\s*<\/script>/,
                    "\\1<%= Vite.vite_client() %>\n\n\\1<%= Vite.vite_assets(\"css/app.css\") %>\n\n\\1<%= Vite.vite_assets(\"js/app.#{app_ext}\") %>"
                  )
                  # Pattern 1: CSS link with ~p sigil (handles /assets/css/app.css path)
                  |> String.replace(
                    ~r/<link[^>]+href={~p"\/assets\/css\/app\.css"}[^>]*>/,
                    "<%= Vite.vite_assets(\"css/app.css\") %>"
                  )
                  # Pattern 2: JS script with ~p sigil (handles /assets/js/app.js path)
                  |> String.replace(
                    ~r/<script[^>]+src={~p"\/assets\/js\/app\.js"}[^>]*>\s*<\/script>/,
                    "<%= Vite.vite_assets(\"js/app.#{app_ext}\") %>"
                  )
                  # Pattern 3: Legacy patterns for older Phoenix apps
                  |> String.replace(
                    ~r/<link[^>]+href={~p"\/assets\/app\.css"}[^>]*>/,
                    "<%= Vite.vite_assets(\"css/app.css\") %>"
                  )
                  |> String.replace(
                    ~r/<script[^>]+src={~p"\/assets\/app\.js"}[^>]*>\s*<\/script>/,
                    "<%= Vite.vite_assets(\"js/app.#{app_ext}\") %>"
                  )
                  # Pattern 4: Routes.static_path pattern (older Phoenix)
                  |> String.replace(
                    ~r/<link[^>]+href={Routes\.static_path\(@conn,\s*"\/assets\/app\.css"\)}[^>]*>/,
                    "<%= Vite.vite_assets(\"css/app.css\") %>"
                  )
                  |> String.replace(
                    ~r/<script[^>]+src={Routes\.static_path\(@conn,\s*"\/assets\/app\.js"\)}[^>]*>\s*<\/script>/,
                    "<%= Vite.vite_assets(\"js/app.#{app_ext}\") %>"
                  )

                # Add vite_client if not already present and we made replacements
                # Only needed if the combined pattern didn't match
                updated =
                  if not String.contains?(updated, "vite_client") and updated != content do
                    String.replace(
                      updated,
                      ~r/(\s*)(<%= Vite\.vite_assets\("css\/app\.css"\) %>)/,
                      "\\1<%= Vite.vite_client() %>\n\n\\1\\2",
                      global: false
                    )
                  else
                    updated
                  end

                # Add react_refresh after vite_client if React is enabled
                if react and not String.contains?(updated, "react_refresh") do
                  String.replace(
                    updated,
                    "<%= Vite.vite_client() %>",
                    "<%= Vite.vite_client() %>\n    <%= Vite.react_refresh() %>"
                  )
                else
                  updated
                end
              end

            content ->
              content
          end)
        end)

      if inertia do
        # For Inertia, we also need to create a separate inertia_root layout
        inertia_layout_path =
          Path.join([
            "lib",
            web_dir(igniter),
            "components",
            "layouts",
            "inertia_root.html.heex"
          ])

        content = inertia_root_html(igniter)

        igniter
        |> Igniter.create_new_file(inertia_layout_path, content, on_exists: :skip)
        |> Igniter.add_notice("""
        Created Inertia root layout at #{inertia_layout_path}

        To use Inertia in your application:
        1. Update your router to use the Inertia plug
        2. In your controllers, use `render_inertia(conn, "PageName")`
        3. Create React components in assets/js/pages/
        """)
      else
        igniter
      end
    end

    defp web_dir(igniter) do
      igniter
      |> Igniter.Libs.Phoenix.web_module()
      |> inspect()
      |> Macro.underscore()
    end

    defp inertia_root_html(igniter) do
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"

      # For TypeScript, we need to load both app.ts (Phoenix) and app.tsx (Inertia)
      app_scripts =
        if typescript do
          """
            <%= Vite.vite_assets("js/app.tsx") %>
          """
        else
          """
            <%= Vite.vite_assets("js/app.#{extension}") %>
          """
        end

      """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="csrf-token" content={get_csrf_token()} />
          <.inertia_title><%= assigns[:page_title] %></.inertia_title>
          <.inertia_head content={@inertia_head} />
          <%= Vite.vite_client() %>
          <%= Vite.react_refresh() %>
          <%= Vite.vite_assets("css/app.css") %>#{app_scripts}
        </head>
        <body>
          {@inner_content}
        </body>
      </html>
      """
    end

    def setup_assets(igniter) do
      typescript = igniter.args.options[:typescript] || false
      react = igniter.args.options[:react] || false
      inertia = igniter.args.options[:inertia] || false

      file_extension = if typescript, do: "ts", else: "js"

      igniter
      |> create_app_js(file_extension, react, inertia, typescript)
      |> create_app_css()
      |> maybe_create_typescript_config(typescript, react)
    end

    defp create_app_js(igniter, extension, react, inertia, typescript) do
      cond do
        inertia ->
          # For Inertia, we need JSX/TSX files
          entry_extension = if extension == "ts", do: "tsx", else: "jsx"

          # Create the Inertia app entry point
          content = inertia_app_content(entry_extension)

          igniter
          |> Igniter.create_new_file("assets/js/app.#{entry_extension}", content,
            on_exists: :overwrite
          )
          |> maybe_create_pages_directory()
          |> then(fn igniter ->
            # Always rename app.js to app.ts when TypeScript is enabled
            if typescript && Igniter.exists?(igniter, "assets/js/app.js") do
              Igniter.move_file(igniter, "assets/js/app.js", "assets/js/app.ts")
            else
              igniter
            end
          end)

        react ->
          # For React (not Inertia), create a JSX/TSX file
          entry_extension = if typescript, do: "tsx", else: "jsx"
          content = react_app_content(extension)

          igniter
          |> Igniter.create_new_file("assets/js/app.#{entry_extension}", content,
            on_exists: :overwrite
          )

        true ->
          # For non-React projects, handle TypeScript conversion if needed
          if typescript && Igniter.exists?(igniter, "assets/js/app.js") do
            # Rename app.js to app.ts when TypeScript is enabled
            Igniter.move_file(igniter, "assets/js/app.js", "assets/js/app.ts", on_exists: :skip)
          else
            igniter
          end
      end
    end

    defp create_app_css(igniter) do
      # Phoenix always generates app.css, so we don't need to create it
      # Just return the igniter as-is
      igniter
    end

    defp react_app_content(_extension) do
      """
      import React from "react"
      import { createRoot } from "react-dom/client"

      // Phoenix specific imports
      import "phoenix_html"
      import { Socket } from "phoenix"
      import { LiveSocket } from "phoenix_live_view"

      // Example React component
      function App() {
        return (
          <div className="app">
            <h1>Welcome to Phoenix with Vite and React!</h1>
          </div>
        )
      }

      // Mount React app if there's a root element
      const rootElement = document.getElementById("react-root")
      if (rootElement) {
        const root = createRoot(rootElement)
        root.render(<App />)
      }

      // Phoenix LiveView setup
      let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
      let liveSocket = new LiveSocket("/live", Socket, {
        longPollFallbackMs: 2500,
        params: { _csrf_token: csrfToken }
      })

      // Connect if there are any LiveViews on the page
      liveSocket.connect()

      // Expose liveSocket on window for web console debug logs and latency simulation
      window.liveSocket = liveSocket
      """
    end

    defp inertia_app_content(extension) do
      """
      import React from "react";
      import axios from "axios";

      import { createInertiaApp } from "@inertiajs/react";
      import { createRoot } from "react-dom/client";

      axios.defaults.xsrfHeaderName = "x-csrf-token";

      createInertiaApp({
        resolve: async (name) => {
          return await import(`./pages/${name}.#{extension}`);
        },
        setup({ App, el, props }) {
          createRoot(el).render(<App {...props} />);
        },
      });
      """
    end

    defp maybe_create_pages_directory(igniter) do
      # Create an example page component
      typescript = igniter.args.options[:typescript] || false
      extension = if typescript, do: "tsx", else: "jsx"
      {igniter, has_tailwind} = detect_tailwind(igniter)

      example_content =
        if typescript do
          build_home_component_tsx(has_tailwind)
        else
          build_home_component_jsx(has_tailwind)
        end

      Igniter.create_new_file(igniter, "assets/js/pages/Home.#{extension}", example_content,
        on_exists: :skip
      )
    end

    defp build_home_component_tsx(has_tailwind) do
      if has_tailwind do
        """
        import React from "react";

        interface HomeProps {
          greeting: string;
        }

        export default function Home({ greeting }: HomeProps) {
          return (
            <div className="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
              <div className="container mx-auto px-4 py-16">
                {/* Hero Section */}
                <div className="text-center mb-16">
                  <h1 className="text-5xl md:text-6xl font-bold text-gray-900 dark:text-white mb-4">
                    {greeting}
                  </h1>
                  <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
                    Built with Phoenix, Inertia.js, React, and Vite
                  </p>
                  <div className="flex gap-4 justify-center">
                    <a
                      href="https://hexdocs.pm/phoenix"
                      className="px-6 py-3 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
                    >
                      Phoenix Docs
                    </a>
                    <a
                      href="https://inertiajs.com"
                      className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    >
                      Inertia.js Docs
                    </a>
                  </div>
                </div>

                {/* Features Grid */}
                <div className="grid md:grid-cols-3 gap-8 mb-16">
                  <FeatureCard
                    title="⚡ Lightning Fast"
                    description="Vite provides instant HMR and blazing fast builds for the best developer experience."
                  />
                  <FeatureCard
                    title="🚀 Modern Stack"
                    description="Phoenix LiveView + Inertia.js + React creates powerful, reactive applications."
                  />
                  <FeatureCard
                    title="🛡️ Type Safe"
                    description="Full TypeScript support ensures your code is robust and maintainable."
                  />
                </div>

                {/* Code Example */}
                <div className="bg-gray-900 rounded-lg p-6 mb-16">
                  <h2 className="text-2xl font-bold text-white mb-4">Quick Start</h2>
                  <pre className="text-green-400 overflow-x-auto">
                    <code>{`# Create a new Inertia page
        def index(conn, _params) do
          conn
          |> assign_prop(:users, Accounts.list_users())
          |> assign_prop(:title, "User List")
          |> render_inertia("Users/Index")
        end`}</code>
                  </pre>
                </div>

                {/* Next Steps */}
                <div className="text-center">
                  <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
                    Ready to build something amazing?
                  </h2>
                  <p className="text-lg text-gray-600 dark:text-gray-300">
                    Start by editing <code className="bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded">assets/js/pages/Home.tsx</code>
                  </p>
                </div>
              </div>
            </div>
          );
        }

        interface FeatureCardProps {
          title: string;
          description: string;
        }

        function FeatureCard({ title, description }: FeatureCardProps) {
          return (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                {title}
              </h3>
              <p className="text-gray-600 dark:text-gray-300">
                {description}
              </p>
            </div>
          );
        }
        """
      else
        """
        import React from "react";

        interface HomeProps {
          greeting: string;
        }

        export default function Home({ greeting }: HomeProps) {
          return (
            <div style={{ minHeight: '100vh', background: 'linear-gradient(to bottom right, #f3e7ff, #e0e7ff)', padding: '2rem' }}>
              <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
                {/* Hero Section */}
                <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
                  <h1 style={{ fontSize: '3.5rem', fontWeight: 'bold', color: '#1a202c', marginBottom: '1rem' }}>
                    {greeting}
                  </h1>
                  <p style={{ fontSize: '1.25rem', color: '#4a5568', marginBottom: '2rem' }}>
                    Built with Phoenix, Inertia.js, React, and Vite
                  </p>
                  <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
                    <a
                      href="https://hexdocs.pm/phoenix"
                      style={{
                        padding: '0.75rem 1.5rem',
                        backgroundColor: '#f97316',
                        color: 'white',
                        borderRadius: '0.5rem',
                        textDecoration: 'none',
                        transition: 'background-color 0.2s'
                      }}
                      onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#ea580c'}
                      onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#f97316'}
                    >
                      Phoenix Docs
                    </a>
                    <a
                      href="https://inertiajs.com"
                      style={{
                        padding: '0.75rem 1.5rem',
                        backgroundColor: '#9333ea',
                        color: 'white',
                        borderRadius: '0.5rem',
                        textDecoration: 'none',
                        transition: 'background-color 0.2s'
                      }}
                      onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#7c3aed'}
                      onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#9333ea'}
                    >
                      Inertia.js Docs
                    </a>
                  </div>
                </div>

                {/* Features */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem', marginBottom: '4rem' }}>
                  <FeatureCard
                    title="⚡ Lightning Fast"
                    description="Vite provides instant HMR and blazing fast builds for the best developer experience."
                  />
                  <FeatureCard
                    title="🚀 Modern Stack"
                    description="Phoenix LiveView + Inertia.js + React creates powerful, reactive applications."
                  />
                  <FeatureCard
                    title="🛡️ Type Safe"
                    description="Full TypeScript support ensures your code is robust and maintainable."
                  />
                </div>

                {/* Code Example */}
                <div style={{ backgroundColor: '#1a202c', borderRadius: '0.5rem', padding: '1.5rem', marginBottom: '4rem' }}>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'white', marginBottom: '1rem' }}>
                    Quick Start
                  </h2>
                  <pre style={{ color: '#68d391', overflowX: 'auto' }}>
                    <code>{`# Create a new Inertia page
        def index(conn, _params) do
          conn
          |> assign_prop(:users, Accounts.list_users())
          |> assign_prop(:title, "User List")
          |> render_inertia("Users/Index")
        end`}</code>
                  </pre>
                </div>

                {/* Next Steps */}
                <div style={{ textAlign: 'center' }}>
                  <h2 style={{ fontSize: '2rem', fontWeight: 'bold', color: '#1a202c', marginBottom: '1rem' }}>
                    Ready to build something amazing?
                  </h2>
                  <p style={{ fontSize: '1.125rem', color: '#4a5568' }}>
                    Start by editing <code style={{ backgroundColor: '#e2e8f0', padding: '0.25rem 0.5rem', borderRadius: '0.25rem' }}>assets/js/pages/Home.tsx</code>
                  </p>
                </div>
              </div>
            </div>
          );
        }

        interface FeatureCardProps {
          title: string;
          description: string;
        }

        function FeatureCard({ title, description }: FeatureCardProps) {
          return (
            <div style={{
              backgroundColor: 'white',
              borderRadius: '0.5rem',
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
              padding: '1.5rem',
              transition: 'box-shadow 0.2s'
            }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#1a202c', marginBottom: '0.5rem' }}>
                {title}
              </h3>
              <p style={{ color: '#4a5568' }}>
                {description}
              </p>
            </div>
          );
        }
        """
      end
    end

    defp build_home_component_jsx(has_tailwind) do
      if has_tailwind do
        """
        import React from "react";

        export default function Home({ greeting }) {
          return (
            <div className="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
              <div className="container mx-auto px-4 py-16">
                {/* Hero Section */}
                <div className="text-center mb-16">
                  <h1 className="text-5xl md:text-6xl font-bold text-gray-900 dark:text-white mb-4">
                    {greeting}
                  </h1>
                  <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
                    Built with Phoenix, Inertia.js, React, and Vite
                  </p>
                  <div className="flex gap-4 justify-center">
                    <a
                      href="https://hexdocs.pm/phoenix"
                      className="px-6 py-3 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
                    >
                      Phoenix Docs
                    </a>
                    <a
                      href="https://inertiajs.com"
                      className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    >
                      Inertia.js Docs
                    </a>
                  </div>
                </div>

                {/* Features Grid */}
                <div className="grid md:grid-cols-3 gap-8 mb-16">
                  <FeatureCard
                    title="⚡ Lightning Fast"
                    description="Vite provides instant HMR and blazing fast builds for the best developer experience."
                  />
                  <FeatureCard
                    title="🚀 Modern Stack"
                    description="Phoenix LiveView + Inertia.js + React creates powerful, reactive applications."
                  />
                  <FeatureCard
                    title="🛡️ Type Safe"
                    description="Full TypeScript support ensures your code is robust and maintainable."
                  />
                </div>

                {/* Code Example */}
                <div className="bg-gray-900 rounded-lg p-6 mb-16">
                  <h2 className="text-2xl font-bold text-white mb-4">Quick Start</h2>
                  <pre className="text-green-400 overflow-x-auto">
                    <code>{`# Create a new Inertia page
        def index(conn, _params) do
          conn
          |> assign_prop(:users, Accounts.list_users())
          |> assign_prop(:title, "User List")
          |> render_inertia("Users/Index")
        end`}</code>
                  </pre>
                </div>

                {/* Next Steps */}
                <div className="text-center">
                  <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
                    Ready to build something amazing?
                  </h2>
                  <p className="text-lg text-gray-600 dark:text-gray-300">
                    Start by editing <code className="bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded">assets/js/pages/Home.jsx</code>
                  </p>
                </div>
              </div>
            </div>
          );
        }

        function FeatureCard({ title, description }) {
          return (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                {title}
              </h3>
              <p className="text-gray-600 dark:text-gray-300">
                {description}
              </p>
            </div>
          );
        }
        """
      else
        """
        import React from "react";

        export default function Home({ greeting }) {
          return (
            <div style={{ minHeight: '100vh', background: 'linear-gradient(to bottom right, #f3e7ff, #e0e7ff)', padding: '2rem' }}>
              <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
                {/* Hero Section */}
                <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
                  <h1 style={{ fontSize: '3.5rem', fontWeight: 'bold', color: '#1a202c', marginBottom: '1rem' }}>
                    {greeting}
                  </h1>
                  <p style={{ fontSize: '1.25rem', color: '#4a5568', marginBottom: '2rem' }}>
                    Built with Phoenix, Inertia.js, React, and Vite
                  </p>
                  <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
                    <a
                      href="https://hexdocs.pm/phoenix"
                      style={{
                        padding: '0.75rem 1.5rem',
                        backgroundColor: '#f97316',
                        color: 'white',
                        borderRadius: '0.5rem',
                        textDecoration: 'none',
                        transition: 'background-color 0.2s'
                      }}
                      onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#ea580c'}
                      onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#f97316'}
                    >
                      Phoenix Docs
                    </a>
                    <a
                      href="https://inertiajs.com"
                      style={{
                        padding: '0.75rem 1.5rem',
                        backgroundColor: '#9333ea',
                        color: 'white',
                        borderRadius: '0.5rem',
                        textDecoration: 'none',
                        transition: 'background-color 0.2s'
                      }}
                      onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#7c3aed'}
                      onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#9333ea'}
                    >
                      Inertia.js Docs
                    </a>
                  </div>
                </div>

                {/* Features */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem', marginBottom: '4rem' }}>
                  <FeatureCard
                    title="⚡ Lightning Fast"
                    description="Vite provides instant HMR and blazing fast builds for the best developer experience."
                  />
                  <FeatureCard
                    title="🚀 Modern Stack"
                    description="Phoenix LiveView + Inertia.js + React creates powerful, reactive applications."
                  />
                  <FeatureCard
                    title="🛡️ Type Safe"
                    description="Full TypeScript support ensures your code is robust and maintainable."
                  />
                </div>

                {/* Code Example */}
                <div style={{ backgroundColor: '#1a202c', borderRadius: '0.5rem', padding: '1.5rem', marginBottom: '4rem' }}>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'white', marginBottom: '1rem' }}>
                    Quick Start
                  </h2>
                  <pre style={{ color: '#68d391', overflowX: 'auto' }}>
                    <code>{`# Create a new Inertia page
        def index(conn, _params) do
          conn
          |> assign_prop(:users, Accounts.list_users())
          |> assign_prop(:title, "User List")
          |> render_inertia("Users/Index")
        end`}</code>
                  </pre>
                </div>

                {/* Next Steps */}
                <div style={{ textAlign: 'center' }}>
                  <h2 style={{ fontSize: '2rem', fontWeight: 'bold', color: '#1a202c', marginBottom: '1rem' }}>
                    Ready to build something amazing?
                  </h2>
                  <p style={{ fontSize: '1.125rem', color: '#4a5568' }}>
                    Start by editing <code style={{ backgroundColor: '#e2e8f0', padding: '0.25rem 0.5rem', borderRadius: '0.25rem' }}>assets/js/pages/Home.jsx</code>
                  </p>
                </div>
              </div>
            </div>
          );
        }

        function FeatureCard({ title, description }) {
          return (
            <div style={{
              backgroundColor: 'white',
              borderRadius: '0.5rem',
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
              padding: '1.5rem',
              transition: 'box-shadow 0.2s'
            }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#1a202c', marginBottom: '0.5rem' }}>
                {title}
              </h3>
              <p style={{ color: '#4a5568' }}>
                {description}
              </p>
            </div>
          );
        }
        """
      end
    end

    defp maybe_create_typescript_config(igniter, false, _), do: igniter

    defp maybe_create_typescript_config(igniter, true, react) do
      config =
        if react do
          react_tsconfig_json()
        else
          basic_tsconfig_json()
        end

      Igniter.create_new_file(igniter, "assets/tsconfig.json", config, on_exists: :skip)
    end

    defp basic_tsconfig_json do
      """
      {
        "compilerOptions": {
          "baseUrl": ".",
          "paths": {
            "@/*": ["./js/*"]
          },
          "target": "ES2020",
          "useDefineForClassFields": true,
          "module": "ESNext",
          "lib": ["ES2020", "DOM", "DOM.Iterable"],
          "skipLibCheck": true,
          "moduleResolution": "bundler",
          "allowImportingTsExtensions": true,
          "resolveJsonModule": true,
          "isolatedModules": true,
          "moduleDetection": "force",
          "noEmit": true,
          "strict": true,
          "noUnusedLocals": true,
          "noUnusedParameters": true,
          "noFallthroughCasesInSwitch": true,
          "noUncheckedSideEffectImports": true
        },
        "include": ["js/**/*"]
      }
      """
    end

    defp react_tsconfig_json do
      """
      {
        "compilerOptions": {
          "baseUrl": ".",
          "paths": {
            "@/*": ["./js/*"]
          },
          "target": "ES2020",
          "useDefineForClassFields": true,
          "lib": ["ES2020", "DOM", "DOM.Iterable"],
          "module": "ESNext",
          "skipLibCheck": true,
          "moduleResolution": "bundler",
          "allowImportingTsExtensions": true,
          "resolveJsonModule": true,
          "isolatedModules": true,
          "moduleDetection": "force",
          "noEmit": true,
          "jsx": "react-jsx",
          "strict": true,
          "noUnusedLocals": true,
          "noUnusedParameters": true,
          "noFallthroughCasesInSwitch": true,
          "noUncheckedSideEffectImports": true
        },
        "include": ["js/**/*"]
      }
      """
    end

    def update_mix_aliases_for_system_package_managers(igniter) do
      # Bun aliases are handled by BunIntegration
      if BunIntegration.using_bun?(igniter) do
        igniter
      else
        # Use vitex tasks (which detect package manager automatically)
        igniter
        |> Igniter.Project.TaskAliases.modify_existing_alias("assets.setup", fn zipper ->
          {:ok,
           Sourceror.Zipper.replace(
             zipper,
             quote(do: ["vitex.install --if-missing", "vitex.deps"])
           )}
        end)
        |> Igniter.Project.TaskAliases.modify_existing_alias("assets.build", fn zipper ->
          {:ok, Sourceror.Zipper.replace(zipper, quote(do: ["vitex.deps", "vitex build"]))}
        end)
        |> Igniter.Project.TaskAliases.modify_existing_alias("assets.deploy", fn zipper ->
          {:ok,
           Sourceror.Zipper.replace(
             zipper,
             quote(do: ["vitex.deps", "vitex build", "phx.digest"])
           )}
        end)
      end
    end

    defp detect_topbar(igniter) do
      # Check if app.js imports topbar from vendor
      # This runs BEFORE setup_assets, so the file is still app.js
      app_js_path = "assets/js/app.js"

      if Igniter.exists?(igniter, app_js_path) do
        updated_igniter = Igniter.include_existing_file(igniter, app_js_path)
        source = Rewrite.source!(updated_igniter.rewrite, app_js_path)
        content = Rewrite.Source.get(source, :content)

        has_topbar_import = String.contains?(content, "../vendor/topbar")

        has_vendored_topbar =
          Igniter.exists?(updated_igniter, "assets/vendor/topbar.js")

        {updated_igniter, has_topbar_import || has_vendored_topbar}
      else
        {igniter, false}
      end
    end

    defp update_js_for_npm_topbar(igniter) do
      # Update app.js - this runs BEFORE setup_assets renames it to app.ts
      js_path = "assets/js/app.js"

      if Igniter.exists?(igniter, js_path) do
        update_topbar_imports_in_file(igniter, js_path)
      else
        igniter
      end
    end

    defp update_topbar_imports_in_file(igniter, file_path) do
      igniter
      |> Igniter.include_existing_file(file_path)
      |> Igniter.update_file(file_path, fn source ->
        Rewrite.Source.update(source, :content, fn
          content when is_binary(content) ->
            # Replace vendored topbar import with npm version
            content
            |> String.replace(
              ~r/import\s+topbar\s+from\s+"\.\.\/vendor\/topbar"/,
              "import topbar from \"topbar\""
            )
            |> String.replace(
              ~r/import\s+topbar\s+from\s+'\.\.\/vendor\/topbar'/,
              "import topbar from \"topbar\""
            )

          content ->
            content
        end)
      end)
    end

    defp remove_vendored_topbar(igniter) do
      vendored_file = "assets/vendor/topbar.js"

      if Igniter.exists?(igniter, vendored_file) do
        Igniter.rm(igniter, vendored_file)
      else
        igniter
      end
    end

    defp detect_daisyui(igniter) do
      app_css_path = "assets/css/app.css"

      # Check if app.css exists and contains daisyUI references
      has_daisyui_in_css =
        if Igniter.exists?(igniter, app_css_path) do
          updated_igniter = Igniter.include_existing_file(igniter, app_css_path)

          source = Rewrite.source!(updated_igniter.rewrite, app_css_path)
          content = Rewrite.Source.get(source, :content)
          has_daisyui = String.contains?(content, "daisyui")
          {updated_igniter, has_daisyui}
        else
          {igniter, false}
        end

      # Check for vendored daisyUI files
      {igniter, has_css} = has_daisyui_in_css

      has_vendored_daisyui =
        Igniter.exists?(igniter, "assets/vendor/daisyui.js") ||
          Igniter.exists?(igniter, "assets/vendor/daisyui-theme.js")

      {igniter, has_css || has_vendored_daisyui}
    end

    defp update_css_for_npm_daisyui(igniter) do
      app_css_path = "assets/css/app.css"

      if Igniter.exists?(igniter, app_css_path) do
        igniter
        |> Igniter.include_existing_file(app_css_path)
        |> Igniter.update_file(app_css_path, fn source ->
          Rewrite.Source.update(source, :content, fn
            content when is_binary(content) ->
              # Replace vendored daisyUI imports with npm version
              content
              |> String.replace(~r/@plugin\s+"\.\.\/vendor\/daisyui"/, "@plugin \"daisyui\"")
              |> String.replace(
                ~r/@plugin\s+"\.\.\/vendor\/daisyui-theme"/,
                "@plugin \"daisyui/theme\""
              )
              |> String.replace(~r/@plugin\s+'\.\.\/vendor\/daisyui'/, "@plugin \"daisyui\"")
              |> String.replace(
                ~r/@plugin\s+'\.\.\/vendor\/daisyui-theme'/,
                "@plugin \"daisyui/theme\""
              )

            content ->
              content
          end)
        end)
      else
        igniter
      end
    end

    defp remove_vendored_daisyui(igniter) do
      vendored_files = [
        "assets/vendor/daisyui.js",
        "assets/vendor/daisyui-theme.js"
      ]

      Enum.reduce(vendored_files, igniter, fn file, acc_igniter ->
        if Igniter.exists?(acc_igniter, file) do
          Igniter.rm(acc_igniter, file)
        else
          acc_igniter
        end
      end)
    end

    def maybe_setup_shadcn(igniter) do
      if igniter.args.options[:shadcn] do
        # Queue the shadcn init command to run after npm install
        base_color = igniter.args.options[:base_color] || "neutral"

        # Determine which package manager command to use
        shadcn_cmd =
          case BunIntegration.install_command(igniter) do
            nil ->
              [
                "cmd",
                [
                  "bunx --bun shadcn@latest init -y --base-color #{base_color} --css-variables --cwd assets"
                ]
              ]

            install_cmd when is_binary(install_cmd) ->
              runner =
                cond do
                  install_cmd =~ "bun" -> "bunx"
                  install_cmd =~ "pnpm" -> "pnpm dlx"
                  install_cmd =~ "yarn" -> "yarn dlx"
                  true -> "npx"
                end

              [
                "cmd",
                [
                  "#{runner} shadcn@latest init -y --base-color #{base_color} --css-variables --cwd assets"
                ]
              ]
          end

        Igniter.add_task(igniter, Enum.at(shadcn_cmd, 0), Enum.at(shadcn_cmd, 1))
      else
        igniter
      end
    end

    def print_next_steps(igniter) do
      notices = build_installation_notices(igniter.args.options)

      Enum.reduce(notices, igniter, fn notice, acc ->
        Igniter.add_notice(acc, notice)
      end)
    end

    defp build_installation_notices(options) do
      base_notice = """
      Phoenix Vite has been installed! Here are the next steps:

      1. Vite is now configured as your asset watcher
      2. Your root layout has been updated to use Vite helpers
      3. Run `mix phx.server` to start development with hot module reloading
      """

      notices = [base_notice]
      # Bun notice is now handled by BunIntegration
      notices = maybe_add_react_notice(notices, options)
      notices = maybe_add_typescript_notice(notices, options)
      notices = maybe_add_ssr_notice(notices, options)
      notices = maybe_add_inertia_notice(notices, options)
      notices = maybe_add_shadcn_notice(notices, options)

      notices ++ [build_documentation_notice()]
    end

    defp maybe_add_react_notice(notices, %{react: true} = options) do
      typescript = options[:typescript] || false

      notice = """
      React Configuration:
      - React Fast Refresh is enabled for instant component updates
      - Add a <div id="react-root"></div> to mount React components
      - Import your React components in app.#{if typescript, do: "tsx", else: "jsx"}
      """

      notices ++ [notice]
    end

    defp maybe_add_react_notice(notices, _), do: notices

    defp maybe_add_typescript_notice(notices, %{typescript: true}) do
      notice = """
      TypeScript Configuration:
      - TypeScript is configured with strict mode
      - Your app.js has been created as app.ts
      - Type checking happens in your editor (Vite skips it for speed)
      """

      notices ++ [notice]
    end

    defp maybe_add_typescript_notice(notices, _), do: notices

    defp maybe_add_ssr_notice(notices, %{ssr: true}) do
      notice = """
      SSR Configuration:
      - Create a js/ssr.js file for your server-side rendering logic
      - Use `mix vitex.ssr.build` to build your SSR bundle
      """

      notices ++ [notice]
    end

    defp maybe_add_ssr_notice(notices, _), do: notices

    defp maybe_add_inertia_notice(notices, options) when is_list(options) do
      if Keyword.get(options, :inertia, false) do
        config_notes = build_inertia_config_notes(options)
        extra_config = if config_notes != [], do: "\n" <> Enum.join(config_notes, "\n"), else: ""

        typescript = Keyword.get(options, :typescript, false)

        notice = """
        Inertia.js Configuration:
        - Inertia.js has been configured with React and code splitting
        - Create page components in assets/js/pages/
        - In your controllers, use `assign_prop(conn, :prop, ...) |> render_inertia("PageName")`
        - The Inertia plug and helpers have been added to your application
        - Example page created at assets/js/pages/Home.#{if typescript, do: "tsx", else: "jsx"}#{extra_config}

        To test your setup:
        1. Update a controller action to use Inertia:
           ```elixir
           def index(conn, _params) do
            assign_prop(conn, :greeting, "Hello from Inertia!")
            |> render_inertia("Home")
           end
           ```
        2. Run `mix phx.server` and visit the route
        """

        notices ++ [notice]
      else
        notices
      end
    end

    defp maybe_add_inertia_notice(notices, _), do: notices

    defp build_inertia_config_notes(options) do
      notes = []

      notes =
        if Keyword.get(options, :camelize_props, false) do
          notes ++ ["- Props will be automatically camelized (snake_case → camelCase)"]
        else
          notes
        end

      if Keyword.get(options, :history_encrypt, false) do
        notes ++ ["- Browser history encryption is enabled for security"]
      else
        notes
      end
    end

    defp maybe_add_shadcn_notice(notices, options) do
      if Keyword.get(options, :shadcn) do
        base_color = Keyword.get(options, :base_color, "zinc")

        notice = """
        shadcn/ui Configuration:
        - shadcn/ui has been initialized with the #{base_color} theme
        - Components will be installed in assets/js/components/ui/
        - CSS variables are configured for easy theming
        - Use the cn() utility from @/lib/utils for className merging

        To add components:
          cd assets && npx shadcn@latest add button

        Example usage:
          import { Button } from "@/components/ui/button"

          <Button variant="outline">Click me</Button>
        """

        notices ++ [notice]
      else
        notices
      end
    end

    defp build_documentation_notice do
      """
      For more information, see:
      https://github.com/nordbeam/vitex
      """
    end
  end
else
  # Fallback if Igniter is not installed
  defmodule Mix.Tasks.Vitex.Install do
    @shortdoc "Installs Phoenix Vite | Install `igniter` to use"
    @moduledoc """
    The task 'vitex.install' requires igniter for advanced installation features.

    You can still set up Phoenix Vite using:

        mix vitex.setup

    To use the full installer with automatic configuration, install igniter:

        {:igniter, "~> 0.5", only: [:dev]}

    Then run:

        mix deps.get
        mix vitex.install
    """

    use Mix.Task

    def run(argv) do
      Mix.shell().info("""
      The task 'vitex.install' requires igniter for automatic installation.
      """)
    end
  end
end
