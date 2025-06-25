# Start ExUnit
ExUnit.start()

# Ensure Jason is available for tests
Application.ensure_all_started(:jason)

# Configure test environment
Application.put_env(:phoenix, :environment, :dev)
