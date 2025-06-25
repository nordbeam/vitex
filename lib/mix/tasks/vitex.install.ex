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
        --yes                Don't prompt for confirmations
    """

    use Igniter.Mix.Task
    require Igniter.Code.Common

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
          yes: :boolean
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

      igniter
      |> maybe_add_inertia_dep()
      |> setup_html_helpers()
      |> maybe_setup_inertia()
      |> create_vite_config()
      |> update_package_json()
      |> setup_watcher()
      |> remove_old_watchers()
      |> update_root_layout()
      |> setup_assets()
      |> update_mix_aliases()
      |> print_next_steps()
    end

    def maybe_add_inertia_dep(igniter) do
      if igniter.args.options[:inertia] do
        Igniter.Project.Deps.add_dep(igniter, {:inertia, "~> 2.4"})
      else
        igniter
      end
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
      Igniter.Libs.Phoenix.append_to_pipeline(igniter, :browser, "plug Inertia.Plug")
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

      """
      import { defineConfig } from 'vite'
      import phoenix from '../deps/vitex/priv/static/vitex'#{imports}

      export default defineConfig({
        plugins: [#{plugins}
          phoenix({
            input: #{input_files},
            publicDirectory: '../priv/static',
            buildDirectory: 'assets',
            hotFile: '../priv/hot',
            manifestPath: '../priv/static/assets/manifest.json',#{additional_opts}
          })
        ],#{if options[:typescript], do: "\n        resolve: {\n          alias: {\n            '@': '/js'\n          }\n        }", else: ""}
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
      Igniter.add_task(igniter, "cmd", ["npm install --prefix assets"])
    end

    def setup_watcher(igniter) do
      {igniter, endpoint} = Igniter.Libs.Phoenix.select_endpoint(igniter)

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

      if inertia do
        # For Inertia, we need a completely different root layout
        content = inertia_root_html(igniter)

        if Igniter.exists?(igniter, file_path) do
          igniter
          |> Igniter.add_warning("""
          The root layout needs to be updated for Inertia.js support.
          Please update #{file_path} with the following content:

          #{content}
          """)
          |> Igniter.create_new_file("_inertia_root_layout_example.html.heex", content,
            on_exists: :skip
          )
        else
          Igniter.create_new_file(igniter, file_path, content)
        end
      else
        react = igniter.args.options[:react] || false

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
                  # Pattern 1: Both CSS and JS with ~p sigil (most common in new Phoenix apps)
                  |> String.replace(
                    ~r/(\s*)<link[^>]+href={~p"\/assets\/app\.css"}[^>]*>\s*\n\s*<script[^>]+src={~p"\/assets\/app\.js"}[^>]*>\s*<\/script>/,
                    "\\1<%= Vite.vite_client() %>\n\\1<%= Vite.vite_assets(\"css/app.css\") %>\n\\1<%= Vite.vite_assets(\"js/app.js\") %>"
                  )
                  # Pattern 2: Just CSS with ~p sigil (in case JS is loaded elsewhere)
                  |> String.replace(
                    ~r/<link[^>]+href={~p"\/assets\/app\.css"}[^>]*>/,
                    "<%= Vite.vite_assets(\"css/app.css\") %>"
                  )
                  # Pattern 3: Just JS with ~p sigil
                  |> String.replace(
                    ~r/<script[^>]+src={~p"\/assets\/app\.js"}[^>]*>\s*<\/script>/,
                    "<%= Vite.vite_assets(\"js/app.js\") %>"
                  )
                  # Pattern 4: Routes.static_path pattern (older Phoenix)
                  |> String.replace(
                    ~r/<link[^>]+href={Routes\.static_path\(@conn,\s*"\/assets\/app\.css"\)}[^>]*>/,
                    "<%= Vite.vite_assets(\"css/app.css\") %>"
                  )
                  |> String.replace(
                    ~r/<script[^>]+src={Routes\.static_path\(@conn,\s*"\/assets\/app\.js"\)}[^>]*>\s*<\/script>/,
                    "<%= Vite.vite_assets(\"js/app.js\") %>"
                  )

                # Add vite_client if not already present and we made replacements
                updated =
                  if not String.contains?(updated, "vite_client") and updated != content do
                    String.replace(
                      updated,
                      ~r/(\s*)(<%= Vite\.vite_assets\("css\/app\.css"\) %>)/,
                      "\\1<%= Vite.vite_client() %>\n\\1\\2",
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
      example_content = """
      import React from "react";

      export default function Home({ greeting }) {
        return (
          <div>
            <h1>{greeting}</h1>
            <p>Welcome to your Inertia.js + Phoenix application!</p>
          </div>
        );
      }
      """

      Igniter.create_new_file(igniter, "assets/js/pages/Home.jsx", example_content,
        on_exists: :skip
      )
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

    def update_mix_aliases(igniter) do
      igniter
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.setup", fn zipper ->
        {:ok,
         Sourceror.Zipper.replace(
           zipper,
           quote(do: ["vitex.install --if-missing", "vitex install"])
         )}
      end)
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.build", fn zipper ->
        {:ok, Sourceror.Zipper.replace(zipper, quote(do: ["vitex install", "vitex build"]))}
      end)
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.deploy", fn zipper ->
        {:ok,
         Sourceror.Zipper.replace(
           zipper,
           quote(do: ["vitex install", "vitex build", "phx.digest"])
         )}
      end)
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

    defp print_next_steps(igniter) do
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
      notices = maybe_add_react_notice(notices, options)
      notices = maybe_add_typescript_notice(notices, options)
      notices = maybe_add_ssr_notice(notices, options)
      notices = maybe_add_inertia_notice(notices, options)

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

    defp maybe_add_inertia_notice(notices, %{inertia: true} = options) do
      config_notes = build_inertia_config_notes(options)
      extra_config = if config_notes != [], do: "\n" <> Enum.join(config_notes, "\n"), else: ""

      notice = """
      Inertia.js Configuration:
      - Inertia.js has been configured with React and code splitting
      - Create page components in assets/js/pages/
      - In your controllers, use `assign_prop(conn, :prop, ...) |> render_inertia("PageName")`
      - The Inertia plug and helpers have been added to your application
      - Example page created at assets/js/pages/Home.jsx#{extra_config}

      To test your setup:
      1. Update a controller action to use Inertia:
         ```elixir
         def index(conn, _params) do
          assign(conn, :greeting, "Hello from Inertia!")
          |> render_inertia("Home")
         end
         ```
      2. Run `mix phx.server` and visit the route
      """

      notices ++ [notice]
    end

    defp maybe_add_inertia_notice(notices, _), do: notices

    defp build_inertia_config_notes(options) do
      notes = []

      notes =
        if options[:camelize_props] do
          notes ++ ["- Props will be automatically camelized (snake_case → camelCase)"]
        else
          notes
        end

      if options[:history_encrypt] do
        notes ++ ["- Browser history encryption is enabled for security"]
      else
        notes
      end
    end

    defp build_documentation_notice do
      """
      For more information, see:
      https://github.com/phoenixframework/vitex
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
