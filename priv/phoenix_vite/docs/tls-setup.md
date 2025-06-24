# TLS/HTTPS Support in Phoenix Vite

Phoenix Vite now supports TLS/HTTPS for the development server through environment variables, similar to Laravel's vite-plugin.

## Configuration

To enable HTTPS for your Vite dev server, set the following environment variables:

```bash
# Path to your TLS key file
export VITE_DEV_SERVER_KEY=/path/to/your/key.pem

# Path to your TLS certificate file
export VITE_DEV_SERVER_CERT=/path/to/your/cert.pem

# Set your Phoenix host (optional, will be extracted from PHX_HOST if available)
export PHX_HOST=https://myapp.local
```

## Usage

1. **Generate TLS certificates** (if you don't have them):
   ```bash
   # Using mkcert (recommended for local development)
   mkcert myapp.local
   ```

2. **Set environment variables** in your `.env` file or shell:
   ```bash
   VITE_DEV_SERVER_KEY=./myapp.local-key.pem
   VITE_DEV_SERVER_CERT=./myapp.local.pem
   PHX_HOST=https://myapp.local
   ```

3. **Start your Phoenix server** as usual:
   ```bash
   mix phx.server
   ```

The Vite dev server will automatically use HTTPS with your provided certificates.

## Features

- **Environment-based configuration**: Uses `VITE_DEV_SERVER_KEY` and `VITE_DEV_SERVER_CERT` environment variables
- **Certificate validation**: Checks that certificate files exist and provides helpful error messages if not
- **Automatic host detection**: Extracts host from `PHX_HOST` environment variable (Phoenix convention)
- **Logging**: Shows when TLS is being used in the dev server output
- **HMR support**: Hot Module Replacement works seamlessly over HTTPS

## Error Handling

If certificate files are not found, you'll get a helpful error message:
```
Unable to find the certificate files specified in your environment. 
Ensure you have correctly configured VITE_DEV_SERVER_KEY: [/path/to/key.pem] 
and VITE_DEV_SERVER_CERT: [/path/to/cert.pem].
```

If the host cannot be determined from `PHX_HOST`, you'll see:
```
Unable to determine the host from the environment's PHX_HOST: [undefined].
```

## Differences from Laravel

- Uses `PHX_HOST` instead of `APP_URL` (following Phoenix conventions)
- No built-in Valet/Herd integration (those are Laravel-specific tools)
- Otherwise, the implementation follows the same patterns as Laravel's vite-plugin