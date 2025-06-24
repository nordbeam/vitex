defmodule PhoenixVite do
  @moduledoc """
  Phoenix integration with Vite.
  
  This module provides helpers for integrating Vite with Phoenix applications,
  handling both development and production environments.
  """

  @doc """
  Generate script tags for Vite entries.
  
  In development, this will load scripts from the Vite dev server.
  In production, this will load the built and hashed assets.
  
  ## Examples
  
      <%= PhoenixVite.vite_assets("js/app.js") %>
      <%= PhoenixVite.vite_assets(["js/app.js", "js/admin.js"]) %>
  """
  def vite_assets(entries) when is_list(entries) do
    Enum.map_join(entries, "\n", &vite_assets/1)
  end

  def vite_assets(entry) when is_binary(entry) do
    if dev_server_running?() do
      vite_dev_assets(entry)
    else
      vite_prod_assets(entry)
    end
  end

  @doc """
  Generate a script tag for React Refresh in development.
  
  This should be included before your main application scripts when using React.
  
  ## Example
  
      <%= PhoenixVite.react_refresh() %>
  """
  def react_refresh do
    if dev_server_running?() do
      """
      <script type="module">
        import RefreshRuntime from '#{vite_server_url()}/@react-refresh'
        RefreshRuntime.injectIntoGlobalHook(window)
        window.$RefreshReg$ = () => {}
        window.$RefreshSig$ = () => (type) => type
        window.__vite_plugin_react_preamble_installed__ = true
      </script>
      """
      |> Phoenix.HTML.raw()
    else
      Phoenix.HTML.raw("")
    end
  end

  @doc """
  Generate Vite client script tag for development.
  
  This enables hot module replacement and other development features.
  
  ## Example
  
      <%= PhoenixVite.vite_client() %>
  """
  def vite_client do
    if dev_server_running?() do
      Phoenix.HTML.raw(~s(<script type="module" src="#{vite_server_url()}/@vite/client"></script>))
    else
      Phoenix.HTML.raw("")
    end
  end

  @doc """
  Get the URL for a Vite asset.
  
  In development, returns the dev server URL.
  In production, returns the hashed asset URL from the manifest.
  
  ## Example
  
      <link rel="stylesheet" href={PhoenixVite.asset_path("css/app.css")} />
  """
  def asset_path(path) do
    if dev_server_running?() do
      "#{vite_server_url()}/#{path}"
    else
      manifest_path = get_manifest_path(path)
      "/#{manifest_path}"
    end
  end

  @doc """
  Check if running in development mode with hot module replacement.
  """
  def hmr_enabled? do
    dev_server_running?()
  end

  @doc """
  Get the path to the Vite plugin JavaScript files.
  
  This is used to configure npm/yarn to use the plugin from the Elixir dependency.
  """
  def plugin_path do
    Path.join(:code.priv_dir(:phoenix_vite), "static/phoenix_vite")
  end

  # Private functions

  defp vite_dev_assets(entry) do
    Phoenix.HTML.raw(~s(<script type="module" src="#{vite_server_url()}/#{entry}"></script>))
  end

  defp vite_prod_assets(entry) do
    manifest = load_manifest()
    
    case Map.get(manifest, entry) do
      nil ->
        raise "Vite manifest missing entry for #{entry}"
      
      %{"file" => file} = entry_data ->
        # Add CSS imports
        css_files = Map.get(entry_data, "css", [])
        css_tags = Enum.map(css_files, fn css_file ->
          ~s(<link rel="stylesheet" href="/#{css_file}" />)
        end)
        
        # Add the main script
        script_tag = ~s(<script type="module" crossorigin src="/#{file}"></script>)
        
        # Add preload links for imports
        imports = Map.get(entry_data, "imports", [])
        import_tags = Enum.map(imports, fn import_key ->
          case Map.get(manifest, import_key) do
            %{"file" => import_file} ->
              ~s(<link rel="modulepreload" href="/#{import_file}" />)
            _ ->
              ""
          end
        end)
        
        all_tags = css_tags ++ import_tags ++ [script_tag]
        Phoenix.HTML.raw(Enum.join(all_tags, "\n"))
    end
  end

  defp dev_server_running? do
    case read_hot_file() do
      {:ok, _url} -> true
      _ -> false
    end
  end

  defp vite_server_url do
    case read_hot_file() do
      {:ok, url} -> String.trim(url)
      _ -> raise "Vite dev server is not running"
    end
  end

  defp read_hot_file do
    hot_file_path = Path.join([File.cwd!(), "priv", "hot"])
    
    case File.read(hot_file_path) do
      {:ok, content} -> {:ok, content}
      {:error, _} -> {:error, :not_found}
    end
  end

  defp load_manifest do
    manifest_path = Path.join([File.cwd!(), "priv", "static", "assets", "manifest.json"])
    
    case File.read(manifest_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, manifest} -> manifest
          {:error, _} -> raise "Failed to parse Vite manifest"
        end
      
      {:error, _} ->
        raise "Vite manifest not found. Run 'mix assets.build' to build assets."
    end
  end

  defp get_manifest_path(path) do
    manifest = load_manifest()
    
    case Map.get(manifest, path) do
      %{"file" => file} -> file
      nil -> raise "Asset not found in manifest: #{path}"
    end
  end
end