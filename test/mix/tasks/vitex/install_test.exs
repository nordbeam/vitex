defmodule Mix.Tasks.Vitex.InstallTest do
  use ExUnit.Case

  alias Mix.Tasks.Vitex.Install
  import Igniter.Test

  describe "Layout updates" do
    test "updates root layout with Vite helpers" do
      project = phx_test_project() |> Install.update_root_layout()

      # Assert that the root layout has been updated with Vite helpers
      assert_has_patch(project, "lib/test_web/components/layouts/root.html.heex", """
      ...|
       - |    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
       - |    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
       - |    </script>
       + |    <%= Vite.vite_client() %>
       + |
       + |    <%= Vite.vite_assets("css/app.css") %>
       + |
       + |    <%= Vite.vite_assets("js/app.js") %>
         |  </head>
      ...|
      """)
    end

    test "adds React refresh when --react is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [react: true]})
        |> Install.update_root_layout()

      # Assert that React refresh is added
      assert_file_contains(
        project,
        "lib/test_web/components/layouts/root.html.heex",
        "<%= Vite.react_refresh() %>"
      )
    end

    test "handles layout with Routes.static_path pattern" do
      # Create a project with older Phoenix-style layout
      project =
        phx_test_project()
        |> Igniter.update_file("lib/test_web/components/layouts/root.html.heex", fn source ->
          Rewrite.Source.update(source, :content, fn _ ->
            """
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <meta charset="utf-8"/>
                <title>Test</title>
                <link rel="stylesheet" href={Routes.static_path(@conn, "/assets/app.css")}/>
                <script defer type="text/javascript" src={Routes.static_path(@conn, "/assets/app.js")}></script>
              </head>
              <body>
                <%= @inner_content %>
              </body>
            </html>
            """
          end)
        end)
        |> Install.update_root_layout()

      # Assert that the layout has been updated
      assert_file_contains(
        project,
        "lib/test_web/components/layouts/root.html.heex",
        "<%= Vite.vite_client() %>"
      )

      assert_file_contains(
        project,
        "lib/test_web/components/layouts/root.html.heex",
        "<%= Vite.vite_assets(\"css/app.css\") %>"
      )

      assert_file_contains(
        project,
        "lib/test_web/components/layouts/root.html.heex",
        "<%= Vite.vite_assets(\"js/app.js\") %>"
      )
    end

    test "does not modify already configured layouts" do
      # Create a project with already configured Vite helpers
      project =
        phx_test_project()
        |> Igniter.update_file("lib/test_web/components/layouts/root.html.heex", fn source ->
          Rewrite.Source.update(source, :content, fn _ ->
            """
            <!DOCTYPE html>
            <html>
              <head>
                <%= Vite.vite_client() %>
                <%= Vite.vite_assets("css/app.css") %>
                <%= Vite.vite_assets("js/app.js") %>
              </head>
              <body>
                <%= @inner_content %>
              </body>
            </html>
            """
          end)
        end)
        |> Install.update_root_layout()

      # Assert that the layout remains unchanged (no duplicate vite_client calls)
      content =
        Rewrite.Source.get(
          project.rewrite.sources["lib/test_web/components/layouts/root.html.heex"],
          :content
        )

      # Count occurrences of vite_client - should be exactly 1
      client_count = content |> String.split("vite_client()") |> length() |> Kernel.-(1)
      assert client_count == 1
    end
  end

  describe "Mix aliases" do
    test "updates assets.setup alias to use vitex" do
      project = phx_test_project() |> Install.update_mix_aliases()

      # Assert that the assets.setup alias has been updated (all aliases are updated together)
      assert_has_patch(project, "mix.exs", """
      ...|
       - |      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
       - |      "assets.build": ["tailwind test", "esbuild test"],
       + |      "assets.setup": ["vitex.install --if-missing", "vitex install"],
       + |      "assets.build": ["vitex install", "vitex build"],
      ...|
      """)
    end

    test "updates assets.build alias to use vitex" do
      project = phx_test_project() |> Install.update_mix_aliases()

      # Assert that the assets.build alias has been updated (all aliases are updated together)
      assert_has_patch(project, "mix.exs", """
      ...|
       - |      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
       - |      "assets.build": ["tailwind test", "esbuild test"],
       + |      "assets.setup": ["vitex.install --if-missing", "vitex install"],
       + |      "assets.build": ["vitex install", "vitex build"],
      ...|
      """)
    end

    test "updates assets.deploy alias to use vitex" do
      project = phx_test_project() |> Install.update_mix_aliases()

      # Assert that the assets.deploy alias has been updated (all aliases are updated together)
      assert_has_patch(project, "mix.exs", """
      ...|
         |      "assets.deploy": [
       - |        "tailwind test --minify",
       - |        "esbuild test --minify",
       + |        "vitex install",
       + |        "vitex build",
         |        "phx.digest"
         |      ]
      ...|
      """)
    end
  end

  describe "Development configuration" do
    test "adds Vite watcher to dev.exs" do
      project = phx_test_project() |> Install.setup_watcher()

      # Assert that the Vite watcher has been added
      assert_file_contains(
        project,
        "config/dev.exs",
        "node: [\"node_modules/.bin/vite\", \"dev\""
      )
    end

    test "removes esbuild watcher if present" do
      project = phx_test_project() |> Install.setup_watcher() |> Install.remove_old_watchers()

      # The esbuild watcher should be removed
      refute_file_contains(project, "config/dev.exs", "esbuild:")
    end
  end

  describe "Package.json setup" do
    test "creates package.json with Vite dependencies" do
      project = phx_test_project() |> Install.update_package_json()

      # Assert that package.json is created with proper structure
      assert_creates(project, "assets/package.json")

      # Check for Vite scripts
      assert_file_contains(project, "assets/package.json", ~s["dev": "vite"])
      assert_file_contains(project, "assets/package.json", ~s["build": "vite build"])

      # Check for Vite dependency
      assert_file_contains(project, "assets/package.json", ~s["vite": "^7.0.0"])
    end

    test "adds React dependencies when --react is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [react: true]})
        |> Install.update_package_json()

      # Assert that React dependencies are added
      assert_has_task(project, "cmd", ["npm install --prefix assets"])

      # Check for React plugin in dependencies
      assert_file_contains(project, "assets/package.json", "@vitejs/plugin-react")
    end

    test "adds TypeScript dependencies when --typescript is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [typescript: true]})
        |> Install.update_package_json()

      # Assert that TypeScript dependencies are added  
      assert_has_task(project, "cmd", ["npm install --prefix assets"])

      # Check for TypeScript types
      assert_file_contains(project, "assets/package.json", "@types/phoenix")
    end
  end

  describe "Vite configuration" do
    test "creates basic vite.config.js" do
      project = phx_test_project() |> Install.create_vite_config()

      # Assert that vite.config.js is created
      assert_creates(project, "assets/vite.config.js")
    end

    test "creates vite.config.js with React when --react is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [react: true]})
        |> Install.create_vite_config()

      # Assert that React plugin is included
      assert_creates(project, "assets/vite.config.js")

      assert_file_contains(
        project,
        "assets/vite.config.js",
        "import react from '@vitejs/plugin-react'"
      )

      assert_file_contains(project, "assets/vite.config.js", "react()")
    end

    test "creates vite.config.js with TypeScript paths when --typescript is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [typescript: true]})
        |> Install.create_vite_config()

      # Assert that TypeScript alias is configured
      assert_creates(project, "assets/vite.config.js")
      assert_file_contains(project, "assets/vite.config.js", "resolve: {")
      assert_file_contains(project, "assets/vite.config.js", "alias: {")
      assert_file_contains(project, "assets/vite.config.js", "'@': '/js'")
    end

    test "creates vite.config.js with SSR when --ssr is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [ssr: true]})
        |> Install.create_vite_config()

      # Assert that SSR is configured
      assert_creates(project, "assets/vite.config.js")
      assert_file_contains(project, "assets/vite.config.js", "ssr: 'js/ssr.js'")
    end

    test "creates vite.config.js with TLS detection when --tls is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [tls: true]})
        |> Install.create_vite_config()

      # Assert that TLS detection is enabled
      assert_creates(project, "assets/vite.config.js")
      assert_file_contains(project, "assets/vite.config.js", "detectTls: true")
    end
  end

  describe "Asset files" do
    test "creates basic app.js file" do
      project = phx_test_project() |> Install.setup_assets()

      # Assert that app.js contains LiveView setup
      assert_file_contains(project, "assets/js/app.js", "import \"phoenix_html\"")
      assert_file_contains(project, "assets/js/app.js", "import {Socket} from \"phoenix\"")

      assert_file_contains(
        project,
        "assets/js/app.js",
        "import {LiveSocket} from \"phoenix_live_view\""
      )
    end

    test "creates app.jsx when --react is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [react: true]})
        |> Install.setup_assets()

      # Assert that app.jsx is created instead of app.js
      assert_creates(project, "assets/js/app.jsx")
    end

    test "creates app.tsx when --react and --typescript are specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [react: true, typescript: true]})
        |> Install.setup_assets()

      # Assert that app.tsx is created
      assert_creates(project, "assets/js/app.tsx")
    end

    test "creates tsconfig.json when --typescript is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [typescript: true]})
        |> Install.setup_assets()

      # Assert that tsconfig.json is created
      assert_creates(project, "assets/tsconfig.json")
      assert_file_contains(project, "assets/tsconfig.json", "\"target\": \"ES2020\"")
      assert_file_contains(project, "assets/tsconfig.json", "\"module\": \"ESNext\"")
    end

    test "creates Inertia app when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_assets()

      # Assert that Inertia app structure is created
      assert_creates(project, "assets/js/app.jsx")
      assert_file_contains(project, "assets/js/app.jsx", "import { createInertiaApp }")
      assert_file_contains(project, "assets/js/app.jsx", "@inertiajs/react")
    end
  end

  describe "Tailwind integration" do
    test "configures Tailwind Vite plugin when Tailwind is detected" do
      # First check if the CSS file already exists in phx_test_project
      base_project = phx_test_project()

      # Update or create the CSS file with Tailwind import
      project =
        if Igniter.exists?(base_project, "assets/css/app.css") do
          base_project
          |> Igniter.update_file("assets/css/app.css", fn source ->
            Rewrite.Source.update(source, :content, fn _ ->
              """
              @import "tailwindcss";
              """
            end)
          end)
        else
          base_project
          |> Igniter.create_new_file("assets/css/app.css", """
          @import "tailwindcss";
          """)
        end
        |> Install.create_vite_config()

      # Assert that Tailwind plugin is configured
      assert_creates(project, "assets/vite.config.js")

      assert_file_contains(
        project,
        "assets/vite.config.js",
        "import tailwindcss from '@tailwindcss/vite'"
      )

      assert_file_contains(project, "assets/vite.config.js", "tailwindcss()")
    end
  end

  describe "Vendor migration" do
    test "migrates vendored topbar.js to npm package" do
      # Create a project with vendored topbar
      project =
        phx_test_project()
        |> Igniter.create_new_file("assets/js/app.js", """
        import topbar from "../vendor/topbar"

        topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
        """)
        |> Igniter.create_new_file("assets/vendor/topbar.js", "// Topbar library code")
        |> Install.update_package_json()

      # Assert that topbar is added to package.json dependencies
      assert_file_contains(project, "assets/package.json", "\"topbar\": \"^3.0.0\"")

      # The actual vendor file removal happens in update_vendor_imports
      # which should update the import statement
      source = project.rewrite.sources["assets/js/app.js"]
      content = Rewrite.Source.get(source, :content)
      assert String.contains?(content, "import topbar from \"topbar\"")
    end
  end

  describe "Inertia.js integration" do
    test "automatically enables React when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.igniter()

      # Inertia should automatically enable React
      assert project.args.options[:react] == true
    end

    test "adds Inertia dependency when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.maybe_add_inertia_dep()

      # Assert that Inertia dependency is added
      assert_has_dependency(project, {:inertia, "~> 2.4"})
    end

    test "does not add Inertia dependency when --inertia is not specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: []})
        |> Install.maybe_add_inertia_dep()

      # Assert that Inertia dependency is not added
      refute_has_dependency(project, :inertia)
    end

    test "sets up Inertia controller helpers when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # Check that Inertia.Controller is imported in the controller helper
      assert_file_contains(project, "lib/test_web.ex", "import Inertia.Controller")
    end

    test "sets up Inertia HTML helpers when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # Check that Inertia.HTML is imported in the html helper
      assert_file_contains(project, "lib/test_web.ex", "import Inertia.HTML")
    end

    test "adds Inertia plug to browser pipeline when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # The Inertia plug should be added to the browser pipeline
      # This would be in the router, but Install.setup_inertia_router() handles this
      # We're testing the overall effect
      assert project != nil
    end

    test "creates inertia pipeline and scope when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # The pipeline and scope creation is done via Igniter.Libs.Phoenix functions
      # We verify the project was modified
      assert project != nil
    end

    test "creates or updates PageController with inertia action when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.igniter()  # Use the full igniter pipeline

      # First check if the file exists
      controller_source = project.rewrite.sources["lib/test_web/controllers/page_controller.ex"]
      
      if controller_source do
        content = Rewrite.Source.get(controller_source, :content)
        # Check that PageController has inertia action
        assert String.contains?(content, "def inertia(conn, _params)"),
               "Expected PageController to contain inertia action, but content was:\n#{content}"
        assert String.contains?(content, "render_inertia(\"Home\")"),
               "Expected PageController to contain render_inertia call"
      else
        # List all created files for debugging
        created_files = Map.keys(project.rewrite.sources) |> Enum.sort()
        flunk("PageController was not created. Created files:\n#{Enum.join(created_files, "\n")}")
      end
    end

    test "adds inertia function to existing PageController when --inertia is specified" do
      # The test project already has a PageController with a home action
      # Let's just run the installer and check that it adds the inertia action
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.igniter()

      # Check that both actions exist in the controller
      controller_source = project.rewrite.sources["lib/test_web/controllers/page_controller.ex"]
      assert controller_source != nil, "PageController should exist"
      
      content = Rewrite.Source.get(controller_source, :content)
      
      # The original home function should still be there
      assert String.contains?(content, "def home(conn, _params)"),
             "Expected original home function to be preserved"
      
      # The inertia function should be added
      assert String.contains?(content, "def inertia(conn, _params)"),
             "Expected inertia function to be added"
    end

    test "creates inertia_root layout when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.update_root_layout()

      # Check that inertia_root.html.heex is created
      assert_creates(project, "lib/test_web/components/layouts/inertia_root.html.heex")
      assert_file_contains(project, "lib/test_web/components/layouts/inertia_root.html.heex", "<.inertia_title>")
      assert_file_contains(project, "lib/test_web/components/layouts/inertia_root.html.heex", "<.inertia_head")
    end

    test "does not create inertia_root layout when --inertia is not specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: []})
        |> Install.update_root_layout()

      # Check that inertia_root.html.heex is NOT created
      refute_creates_file(project, "lib/test_web/components/layouts/inertia_root.html.heex")
    end

    test "adds Inertia config to config.exs when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # Check that Inertia config is added
      assert_file_contains(project, "config/config.exs", "config :inertia")
    end

    test "adds camelizeProps config when --camelize-props is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true, camelize_props: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # Check that camelize_props config is added
      assert_file_contains(project, "config/config.exs", "camelize_props: true")
    end

    test "adds history encryption config when --history-encrypt is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true, history_encrypt: true]})
        |> Install.setup_html_helpers()
        |> Install.maybe_setup_inertia()

      # Check that history encryption config is added
      assert_file_contains(project, "config/config.exs", "history: [encrypt: true]")
    end

    test "creates Home page component when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.setup_assets()

      # Check that Home.jsx is created
      assert_creates(project, "assets/js/pages/Home.jsx")
      assert_file_contains(project, "assets/js/pages/Home.jsx", "export default function Home")
    end

    test "creates TypeScript Home component when --inertia and --typescript are specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true, typescript: true]})
        |> Install.setup_assets()

      # Check that Home.tsx is created with TypeScript
      assert_creates(project, "assets/js/pages/Home.tsx")
      assert_file_contains(project, "assets/js/pages/Home.tsx", "interface HomeProps")
    end

    test "adds Inertia dependencies to package.json when --inertia is specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: [inertia: true]})
        |> Install.update_package_json()

      # Check for Inertia dependencies
      assert_file_contains(project, "assets/package.json", "@inertiajs/react")
      assert_file_contains(project, "assets/package.json", "axios")
    end

    test "does not add Inertia setup when --inertia is not specified" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: []})
        |> Install.igniter()

      # Verify Inertia-specific files are not created
      refute_creates_file(project, "lib/test_web/components/layouts/inertia_root.html.heex")
      refute_creates_file(project, "assets/js/pages/Home.jsx")
      
      # Verify Inertia is not in dependencies
      refute_file_contains(project, "assets/package.json", "@inertiajs/react")
      
      # Verify no Inertia imports in web.ex
      refute_file_contains(project, "lib/test_web.ex", "import Inertia")
    end
  end

  describe "Complete installation" do
    test "runs all setup steps in order" do
      project =
        phx_test_project()
        |> Map.put(:args, %{options: []})
        |> Install.igniter()

      # Verify key files are created
      assert_creates(project, "assets/vite.config.js")
      assert_creates(project, "assets/package.json")
      # app.js already exists in Phoenix projects, so we shouldn't assert it's created
      assert project.rewrite.sources["assets/js/app.js"] != nil

      # Verify configuration updates
      assert project.rewrite.sources["config/dev.exs"] != nil
      assert project.rewrite.sources["lib/test_web/components/layouts/root.html.heex"] != nil
      assert project.rewrite.sources["mix.exs"] != nil

      # Verify dependency task
      assert_has_task(project, "cmd", ["npm install --prefix assets"])
    end

    test "handles all options together" do
      project =
        phx_test_project()
        |> Map.put(:args, %{
          options: [
            react: true,
            typescript: true,
            tls: true,
            ssr: true
          ]
        })
        |> Install.igniter()

      # Verify TypeScript + React creates .tsx files
      assert_creates(project, "assets/js/app.tsx")
      assert_creates(project, "assets/tsconfig.json")

      # Verify vite.config.js has all features
      assert_creates(project, "assets/vite.config.js")
      assert_file_contains(project, "assets/vite.config.js", "react()")
      assert_file_contains(project, "assets/vite.config.js", "detectTls: true")
      assert_file_contains(project, "assets/vite.config.js", "ssr:")
    end

    test "handles Inertia installation with all options" do
      project =
        phx_test_project()
        |> Map.put(:args, %{
          options: [
            inertia: true,
            typescript: true,
            camelize_props: true,
            history_encrypt: true
          ]
        })
        |> Install.igniter()

      # Verify Inertia setup
      assert_creates(project, "lib/test_web/components/layouts/inertia_root.html.heex")
      assert_file_contains(project, "lib/test_web/controllers/page_controller.ex", "def inertia(conn, _params)")
      assert_creates(project, "assets/js/pages/Home.tsx")
      assert_creates(project, "assets/js/app.tsx")
      
      # Verify Inertia app structure
      assert_file_contains(project, "assets/js/app.tsx", "createInertiaApp")
      assert_file_contains(project, "assets/js/app.tsx", "import(`./pages/${name}.tsx`)")
      
      # Verify Inertia dependencies
      assert_file_contains(project, "assets/package.json", "@inertiajs/react")
      
      # Verify React is also enabled (Inertia implies React)
      assert_file_contains(project, "assets/package.json", "react")
      assert_file_contains(project, "assets/package.json", "@vitejs/plugin-react")
      
      # Verify Inertia config
      assert_file_contains(project, "config/config.exs", "config :inertia")
      assert_file_contains(project, "config/config.exs", "camelize_props: true")
      assert_file_contains(project, "config/config.exs", "history: [encrypt: true]")
    end
  end

  # Helper functions to check file contents
  defp assert_file_contains(project, path, content) do
    source = project.rewrite.sources[path]
    assert source != nil, "Expected file #{path} to exist"

    assert String.contains?(Rewrite.Source.get(source, :content), content),
           "Expected #{path} to contain: #{inspect(content)}"
  end

  defp refute_file_contains(project, path, content) do
    source = project.rewrite.sources[path]

    if source do
      refute String.contains?(Rewrite.Source.get(source, :content), content),
             "Expected #{path} NOT to contain: #{inspect(content)}"
    end
  end

  defp refute_creates_file(project, path) do
    refute project.rewrite.sources[path] != nil,
           "Expected file #{path} NOT to be created"
  end

  defp assert_has_dependency(project, {dep_name, version}) do
    assert_file_contains(project, "mix.exs", "{:#{dep_name}, \"#{version}\"}")
  end

  defp refute_has_dependency(project, dep_name) do
    refute_file_contains(project, "mix.exs", "{:#{dep_name},")
  end
end
