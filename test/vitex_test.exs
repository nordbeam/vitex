defmodule VitexTest do
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "vite_client/0" do
    test "returns empty string in production" do
      Application.put_env(:phoenix, :environment, :production)
      assert Vitex.vite_client() == {:safe, ""}
      Application.delete_env(:phoenix, :environment)
    end

    test "returns client script when hot file exists" do
      # Create a temporary hot file
      hot_file_path = Path.join([System.tmp_dir!(), "vitex_test_hot"])
      File.write!(hot_file_path, "http://localhost:5173")

      # Mock the hot file path
      Application.put_env(:vitex, :hot_file, hot_file_path)

      result = Vitex.vite_client()
      html = safe_to_string(result)

      assert html =~ ~s[<script type="module" src="http://localhost:5173/@vite/client"></script>]

      # Cleanup
      File.rm!(hot_file_path)
      Application.delete_env(:vitex, :hot_file)
    end
  end

  describe "react_refresh/0" do
    test "returns empty string in production" do
      Application.put_env(:phoenix, :environment, :production)
      assert Vitex.react_refresh() == {:safe, ""}
      Application.delete_env(:phoenix, :environment)
    end

    test "returns empty string when hot file doesn't exist" do
      Application.put_env(:vitex, :hot_file, "/non/existent/file")
      assert Vitex.react_refresh() == {:safe, ""}
      Application.delete_env(:vitex, :hot_file)
    end

    test "returns React refresh script when in development with hot file" do
      # Create a temporary hot file
      hot_file_path = Path.join([System.tmp_dir!(), "vitex_test_hot"])
      File.write!(hot_file_path, "http://localhost:5173")

      # Mock the hot file path
      Application.put_env(:vitex, :hot_file, hot_file_path)

      result = Vitex.react_refresh()
      html = safe_to_string(result)

      assert html =~ "__vite_plugin_react_preamble"
      assert html =~ "http://localhost:5173/@react-refresh"

      # Cleanup
      File.rm!(hot_file_path)
      Application.delete_env(:vitex, :hot_file)
    end
  end

  describe "vite_assets/1" do
    setup do
      # Create a mock manifest file
      manifest_path = Path.join([System.tmp_dir!(), "vitex_test_manifest.json"])

      manifest_content = %{
        "css/app.css" => %{
          "file" => "assets/app-4e5a6b78.css",
          "isEntry" => true
        },
        "js/app.js" => %{
          "file" => "assets/app-2d4e8b71.js",
          "css" => ["assets/app-4e5a6b78.css"],
          "isEntry" => true
        },
        "js/admin.js" => %{
          "file" => "assets/admin-8a7f3c29.js",
          "imports" => ["_shared-5e8a2b91.js"],
          "isEntry" => true
        },
        "_shared-5e8a2b91.js" => %{
          "file" => "assets/shared-5e8a2b91.js"
        }
      }

      File.write!(manifest_path, Jason.encode!(manifest_content))

      on_exit(fn ->
        File.rm!(manifest_path)
      end)

      {:ok, manifest_path: manifest_path}
    end

    test "returns dev server URL when hot file exists", %{manifest_path: _manifest_path} do
      # Create a temporary hot file
      hot_file_path = Path.join([System.tmp_dir!(), "vitex_test_hot"])
      File.write!(hot_file_path, "http://localhost:5173")

      # Mock the hot file path
      Application.put_env(:vitex, :hot_file, hot_file_path)

      result = Vitex.vite_assets("js/app.js")
      html = safe_to_string(result)

      assert html =~ ~s[<script type="module" crossorigin src="http://localhost:5173/js/app.js"]

      # Cleanup
      File.rm!(hot_file_path)
      Application.delete_env(:vitex, :hot_file)
    end

    test "returns production assets from manifest", %{manifest_path: manifest_path} do
      Application.put_env(:vitex, :manifest_path, manifest_path)
      Application.put_env(:vitex, :static_url_path, "/")

      result = Vitex.vite_assets("js/app.js")
      html = safe_to_string(result)

      # Should include the main script
      assert html =~ ~s[<script type="module" crossorigin src="/assets/app-2d4e8b71.js"]

      # Should include the CSS file
      assert html =~ ~s[<link rel="stylesheet" crossorigin href="/assets/app-4e5a6b78.css"]

      # Cleanup
      Application.delete_env(:vitex, :manifest_path)
      Application.delete_env(:vitex, :static_url_path)
    end

    test "returns CSS link tag for CSS entries", %{manifest_path: manifest_path} do
      Application.put_env(:vitex, :manifest_path, manifest_path)
      Application.put_env(:vitex, :static_url_path, "/")

      result = Vitex.vite_assets("css/app.css")
      html = safe_to_string(result)

      assert html =~ ~s[<link rel="stylesheet" crossorigin href="/assets/app-4e5a6b78.css"]
      refute html =~ "<script"

      # Cleanup
      Application.delete_env(:vitex, :manifest_path)
      Application.delete_env(:vitex, :static_url_path)
    end

    test "includes modulepreload links for imports", %{manifest_path: manifest_path} do
      Application.put_env(:vitex, :manifest_path, manifest_path)
      Application.put_env(:vitex, :static_url_path, "/")

      result = Vitex.vite_assets("js/admin.js")
      html = safe_to_string(result)

      # Should include the main script
      assert html =~ ~s[<script type="module" crossorigin src="/assets/admin-8a7f3c29.js"]

      # Should include modulepreload for shared dependency
      assert html =~ ~s[<link rel="modulepreload" crossorigin href="/assets/shared-5e8a2b91.js"]

      # Cleanup
      Application.delete_env(:vitex, :manifest_path)
      Application.delete_env(:vitex, :static_url_path)
    end

    test "handles multiple entry points", %{manifest_path: manifest_path} do
      Application.put_env(:vitex, :manifest_path, manifest_path)
      Application.put_env(:vitex, :static_url_path, "/")

      result = Vitex.vite_assets(["js/app.js", "js/admin.js"])
      html = safe_to_string(result)

      # Should include both scripts
      assert html =~ ~s[src="/assets/app-2d4e8b71.js"]
      assert html =~ ~s[src="/assets/admin-8a7f3c29.js"]

      # Should include CSS and modulepreload links
      assert html =~ ~s[href="/assets/app-4e5a6b78.css"]
      assert html =~ ~s[href="/assets/shared-5e8a2b91.js"]

      # Cleanup
      Application.delete_env(:vitex, :manifest_path)
      Application.delete_env(:vitex, :static_url_path)
    end

    test "raises error when manifest entry not found", %{manifest_path: manifest_path} do
      Application.put_env(:vitex, :manifest_path, manifest_path)

      assert_raise RuntimeError, ~r/not found in Vite manifest/, fn ->
        Vitex.vite_assets("js/nonexistent.js")
      end

      # Cleanup
      Application.delete_env(:vitex, :manifest_path)
    end
  end

  describe "asset_path/1" do
    test "returns dev server URL when hot file exists" do
      # Create a temporary hot file
      hot_file_path = Path.join([System.tmp_dir!(), "vitex_test_hot"])
      File.write!(hot_file_path, "http://localhost:5173")

      # Mock the hot file path
      Application.put_env(:vitex, :hot_file, hot_file_path)

      assert Vitex.asset_path("js/app.js") == "http://localhost:5173/js/app.js"

      # Cleanup
      File.rm!(hot_file_path)
      Application.delete_env(:vitex, :hot_file)
    end

    test "returns static path in production" do
      Application.put_env(:vitex, :static_url_path, "/assets")

      assert Vitex.asset_path("js/app.js") == "/assets/js/app.js"

      # Cleanup
      Application.delete_env(:vitex, :static_url_path)
    end

    test "uses custom static path function" do
      defmodule TestEndpoint do
        def static_url, do: "https://cdn.example.com"
      end

      static_url_fn = fn path -> TestEndpoint.static_url() <> path end
      Application.put_env(:vitex, :static_url_path, static_url_fn)

      assert Vitex.asset_path("/js/app.js") == "https://cdn.example.com/js/app.js"

      # Cleanup
      Application.delete_env(:vitex, :static_url_path)
    end
  end

  describe "hot file detection" do
    test "correctly detects when dev server is running" do
      # Create a temporary hot file
      hot_file_path = Path.join([System.tmp_dir!(), "vitex_test_hot"])
      File.write!(hot_file_path, "http://localhost:5173")

      # Mock the hot file path
      Application.put_env(:vitex, :hot_file, hot_file_path)

      # The private function hot_running?/0 should return true
      assert Vitex.asset_path("test.js") =~ "localhost:5173"

      # Cleanup
      File.rm!(hot_file_path)
      Application.delete_env(:vitex, :hot_file)
    end

    test "correctly detects when dev server is not running" do
      Application.put_env(:vitex, :hot_file, "/non/existent/file")
      Application.put_env(:vitex, :static_url_path, "/")

      # Should return static path when hot file doesn't exist
      assert Vitex.asset_path("test.js") == "/test.js"

      # Cleanup
      Application.delete_env(:vitex, :hot_file)
      Application.delete_env(:vitex, :static_url_path)
    end
  end

  describe "configuration" do
    test "uses default hot file path" do
      # When no hot_file is configured, it should use the default
      original_hot_file = Application.get_env(:vitex, :hot_file)
      Application.delete_env(:vitex, :hot_file)

      # Should not crash and should use static path
      Application.put_env(:vitex, :static_url_path, "/assets")
      assert Vitex.asset_path("app.js") == "/assets/app.js"

      # Restore original
      if original_hot_file do
        Application.put_env(:vitex, :hot_file, original_hot_file)
      end

      Application.delete_env(:vitex, :static_url_path)
    end

    test "uses default manifest path" do
      # When no manifest_path is configured, it should use the default
      original_manifest = Application.get_env(:vitex, :manifest_path)
      Application.delete_env(:vitex, :manifest_path)

      # Should not crash when trying to read non-existent default manifest
      Application.put_env(:vitex, :static_url_path, "/")

      # This will try to read the default manifest which doesn't exist in tests
      # so we expect it to raise an error with the appropriate message
      assert_raise RuntimeError, ~r/Vite manifest not found/, fn ->
        Vitex.vite_assets("js/app.js")
      end

      # Restore original
      if original_manifest do
        Application.put_env(:vitex, :manifest_path, original_manifest)
      end

      Application.delete_env(:vitex, :static_url_path)
    end
  end
end
