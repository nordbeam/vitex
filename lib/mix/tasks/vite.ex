defmodule Mix.Tasks.Vite do
  @moduledoc """
  Invokes Vite with the given args.
  
  Usage:
  
      $ mix vite COMMAND ARGS
      
  Examples:
  
      $ mix vite build
      $ mix vite dev
      $ mix vite preview
      
  """
  @shortdoc "Invokes Vite with the given args"
  
  use Mix.Task
  
  @impl true
  def run(args) do
    npm_path = find_executable("npm") || find_executable("bun") || find_executable("pnpm") || find_executable("yarn")
    
    unless npm_path do
      raise "No package manager found. Please install npm, bun, pnpm, or yarn."
    end
    
    # Change to assets directory
    assets_dir = Path.join(File.cwd!(), "assets")
    
    unless File.exists?(assets_dir) do
      raise "Assets directory not found at #{assets_dir}"
    end
    
    # Run vite command
    cmd_args = if npm_path =~ "bun" do
      ["x", "--bun", "vite"] ++ args
    else
      ["run", "vite"] ++ args
    end
    
    Mix.shell().cmd("cd #{assets_dir} && #{npm_path} #{Enum.join(cmd_args, " ")}", 
      env: [{"NODE_ENV", node_env()}]
    )
  end
  
  defp find_executable(name) do
    System.find_executable(name)
  end
  
  defp node_env do
    if Mix.env() == :prod, do: "production", else: "development"
  end
end

defmodule Mix.Tasks.Vite.Build do
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
    Mix.Tasks.Vite.Install.run([])
    Mix.Tasks.Vite.run(["build"])
  end
end

defmodule Mix.Tasks.Vite.Install do
  @moduledoc """
  Installs JavaScript dependencies.
  
  Usage:
  
      $ mix vite.install
      
  """
  @shortdoc "Installs JavaScript dependencies"
  
  use Mix.Task
  
  @impl true
  def run(_args) do
    npm_path = find_executable("npm") || find_executable("bun") || find_executable("pnpm") || find_executable("yarn")
    
    unless npm_path do
      raise "No package manager found. Please install npm, bun, pnpm, or yarn."
    end
    
    assets_dir = Path.join(File.cwd!(), "assets")
    
    unless File.exists?(assets_dir) do
      raise "Assets directory not found at #{assets_dir}"
    end
    
    install_cmd = cond do
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