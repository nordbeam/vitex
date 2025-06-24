import fs from "node:fs";
import path from "node:path";
import { AddressInfo } from "node:net";
import {
  Plugin,
  UserConfig,
  ConfigEnv,
  ResolvedConfig,
  Manifest,
  ManifestChunk,
  PluginOption,
} from "vite";
import { OutputChunk } from "rollup";
import colors from "picocolors";
import fullReload, {
  Config as FullReloadConfig,
} from "vite-plugin-full-reload";

interface PluginConfig {
  /**
   * The path or paths of the entry points to compile.
   */
  input: string | string[];

  /**
   * Phoenix's public directory.
   *
   * @default 'priv/static'
   */
  publicDirectory?: string;

  /**
   * The public subdirectory where compiled assets should be written.
   *
   * @default 'assets'
   */
  buildDirectory?: string;

  /**
   * The path to the "hot" file.
   *
   * @default 'priv/hot'
   */
  hotFile?: string;

  /**
   * The path to the manifest file.
   *
   * @default 'priv/static/assets/manifest.json'
   */
  manifestPath?: string;

  /**
   * Enable React Refresh (for React projects).
   *
   * @default false
   */
  reactRefresh?: boolean;

  /**
   * Configuration for performing full page refresh on file changes.
   *
   * {@link https://github.com/ElMassimo/vite-plugin-full-reload}
   * @default false
   */
  refresh?: boolean | string | string[] | RefreshConfig | RefreshConfig[];

  /**
   * Transform the code while serving.
   */
  transformOnServe?: (code: string, url: string) => string;
}

interface RefreshConfig {
  paths: string[];
  config?: FullReloadConfig;
}

interface PhoenixPlugin extends Plugin {
  config: (config: UserConfig, env: ConfigEnv) => UserConfig;
}

type DevServerUrl = `${"http" | "https"}://${string}:${number}`;

let exitHandlersBound = false;

export const refreshPaths = [
  "lib/**/*.ex",
  "lib/**/*.heex",
  "lib/**/*.eex",
  "lib/**/*.leex",
  "lib/**/*.sface",
  "priv/gettext/**/*.po",
].filter((path) => fs.existsSync(path.replace(/\*\*$/, "")));

export default function phoenix(
  config: string | string[] | PluginConfig,
): PluginOption[] {
  const pluginConfig = resolvePluginConfig(config);

  return [
    resolvePhoenixPlugin(pluginConfig),
    ...(resolveFullReloadConfig(pluginConfig) as Plugin[]),
  ];
}

/**
 * Resolve the Phoenix plugin configuration.
 */
function resolvePluginConfig(
  config: string | string[] | PluginConfig,
): Required<PluginConfig> {
  if (typeof config === "string" || Array.isArray(config)) {
    config = { input: config };
  }

  if (typeof config.input === "string") {
    config.input = [config.input];
  }

  if (config.publicDirectory === undefined) {
    config.publicDirectory = "priv/static";
  }

  if (config.buildDirectory === undefined) {
    config.buildDirectory = "assets";
  }

  if (config.hotFile === undefined) {
    config.hotFile = path.join("priv", "hot");
  }

  if (config.manifestPath === undefined) {
    config.manifestPath = path.join(
      config.publicDirectory,
      config.buildDirectory,
      "manifest.json",
    );
  }

  if (config.reactRefresh === undefined) {
    config.reactRefresh = false;
  }

  if (config.refresh === true) {
    config.refresh = [{ paths: refreshPaths }];
  }

  if (config.refresh === undefined) {
    config.refresh = false;
  }

  return config as Required<PluginConfig>;
}

/**
 * Resolve the Phoenix plugin.
 */
function resolvePhoenixPlugin(
  pluginConfig: Required<PluginConfig>,
): PhoenixPlugin {
  let viteDevServerUrl: DevServerUrl;
  let resolvedConfig: ResolvedConfig;
  let userConfig: UserConfig;

  const defaultAliases: Record<string, string> = {
    "@": path.resolve(process.cwd(), "assets/js"),
  };

  // Check for Phoenix ESM files and use them if available
  const phoenixAliases: Record<string, string> = {};
  const depsPath = path.resolve(process.cwd(), "../deps");

  // Check for phoenix.mjs
  if (fs.existsSync(path.join(depsPath, "phoenix/priv/static/phoenix.mjs"))) {
    phoenixAliases["phoenix"] = path.join(
      depsPath,
      "phoenix/priv/static/phoenix.mjs",
    );
  } else if (
    fs.existsSync(path.join(depsPath, "phoenix/priv/static/phoenix.js"))
  ) {
    phoenixAliases["phoenix"] = path.join(
      depsPath,
      "phoenix/priv/static/phoenix.js",
    );
  }

  // Always use phoenix_html.js (no ESM version exists)
  if (
    fs.existsSync(
      path.join(depsPath, "phoenix_html/priv/static/phoenix_html.js"),
    )
  ) {
    phoenixAliases["phoenix_html"] = path.join(
      depsPath,
      "phoenix_html/priv/static/phoenix_html.js",
    );
  }

  // Check for phoenix_live_view.esm.js
  if (
    fs.existsSync(
      path.join(
        depsPath,
        "phoenix_live_view/priv/static/phoenix_live_view.esm.js",
      ),
    )
  ) {
    phoenixAliases["phoenix_live_view"] = path.join(
      depsPath,
      "phoenix_live_view/priv/static/phoenix_live_view.esm.js",
    );
  } else if (
    fs.existsSync(
      path.join(depsPath, "phoenix_live_view/priv/static/phoenix_live_view.js"),
    )
  ) {
    phoenixAliases["phoenix_live_view"] = path.join(
      depsPath,
      "phoenix_live_view/priv/static/phoenix_live_view.js",
    );
  }

  return {
    name: "phoenix",
    enforce: "post",
    config: (config, env) => {
      userConfig = config;
      const assetUrl = "assets";
      const outDir = path.resolve(pluginConfig.publicDirectory);

      return {
        base: env.command === "build" ? `/${assetUrl}/` : "",
        publicDir: false,
        resolve: {
          alias: Array.isArray(userConfig?.resolve?.alias)
            ? [
                ...(userConfig.resolve.alias as Array<{
                  find: string;
                  replacement: string;
                }>),
                ...Object.entries(defaultAliases).map(
                  ([find, replacement]) => ({ find, replacement }),
                ),
                ...Object.entries(phoenixAliases).map(
                  ([find, replacement]) => ({ find, replacement }),
                ),
              ]
            : {
                ...defaultAliases,
                ...phoenixAliases,
                ...(userConfig?.resolve?.alias as Record<string, string>),
              },
        },
        build: {
          manifest: true,
          outDir: outDir,
          emptyOutDir: false,
          assetsDir: assetUrl,
          rollupOptions: {
            input: Array.isArray(pluginConfig.input)
              ? pluginConfig.input.map((entry: string) =>
                  path.resolve(process.cwd(), entry),
                )
              : path.resolve(process.cwd(), pluginConfig.input),
          },
        },
        optimizeDeps: {
          entries: pluginConfig.input,
          include: [
            "phoenix",
            "phoenix_html",
            "phoenix_live_view",
            ...(userConfig?.optimizeDeps?.include || []),
          ],
        },
        server: {
          origin: "__phoenix_vite_placeholder__",
          // Merge any user-provided HMR config
          ...userConfig?.server,
          hmr:
            userConfig?.server?.hmr === false
              ? false
              : {
                  ...(typeof userConfig?.server?.hmr === "object"
                    ? userConfig.server.hmr
                    : {}),
                },
        },
      };
    },
    configResolved(config) {
      resolvedConfig = config;
    },
    transform(code) {
      if (pluginConfig.transformOnServe === undefined) {
        return;
      }

      if (resolvedConfig.command === "serve") {
        return pluginConfig.transformOnServe(code, viteDevServerUrl);
      }

      return;
    },
    configureServer(server) {
      server.httpServer?.once("listening", () => {
        const address = server.httpServer?.address();

        const isAddressInfo = (
          x: string | AddressInfo | null | undefined,
        ): x is AddressInfo => typeof x === "object";
        if (isAddressInfo(address)) {
          viteDevServerUrl = `${server.config.server.https ? "https" : "http"}://localhost:${address.port}`;
          fs.writeFileSync(pluginConfig.hotFile, viteDevServerUrl);

          setTimeout(() => {
            server.config.logger.info(
              `\n  ${colors.cyan(`${colors.bold("PHOENIX")} ${phoenixVersion()}`)}  ${colors.dim("plugin")} ${colors.bold(`v${pluginVersion()}`)}`,
            );
            server.config.logger.info("");
            server.config.logger.info(
              `  ${colors.green("➜")}  Vite: ${colors.cyan(viteDevServerUrl.replace(/:(\d+)/, (_, port: string) => `:${colors.bold(port)}`))}\n`,
            );
          }, 100);
        }
      });

      if (!exitHandlersBound) {
        const clean = () => {
          if (fs.existsSync(pluginConfig.hotFile)) {
            fs.rmSync(pluginConfig.hotFile);
          }
        };

        process.on("exit", clean);
        process.on("SIGINT", () => process.exit());
        process.on("SIGTERM", () => process.exit());
        process.on("SIGHUP", () => process.exit());

        // Terminate the watcher when Phoenix quits
        process.stdin.on("close", () => {
          process.exit(0);
        });
        process.stdin.resume();

        exitHandlersBound = true;
      }

      return () =>
        server.middlewares.use((req, res, next) => {
          if (req.url === "/index.html") {
            res.statusCode = 404;

            res.end(
              fs
                .readFileSync(
                  new URL("./dev-server-index.html", import.meta.url),
                )
                .toString()
                .replace(/{{ PHOENIX_VERSION }}/g, phoenixVersion()),
            );
          }

          next();
        });
    },
    generateBundle(_options, bundle) {
      const manifestChunks = Object.values(bundle)
        .filter(
          (chunk): chunk is OutputChunk =>
            chunk.type === "chunk" && chunk.isEntry,
        )
        .map(
          (chunk): ManifestChunk => ({
            file: chunk.fileName,
            name: chunk.name || "",
            src: chunk.facadeModuleId || undefined,
            isEntry: true,
            imports: chunk.imports,
            css: Array.from(chunk.viteMetadata?.importedCss || []),
            assets: Array.from(chunk.viteMetadata?.importedAssets || []),
          }),
        );

      const manifest = manifestChunks.reduce((manifest, chunk) => {
        if (chunk.src) {
          const assetPath = toPhoenixAssetPath(chunk.src);
          manifest[assetPath] = chunk;
        }
        return manifest;
      }, {} as Manifest);

      const manifestContent = JSON.stringify(manifest, null, 2);
      fs.mkdirSync(path.dirname(pluginConfig.manifestPath), {
        recursive: true,
      });
      fs.writeFileSync(pluginConfig.manifestPath, manifestContent);
    },
  };
}

function toPhoenixAssetPath(filename: string) {
  filename = path.relative(process.cwd(), filename);

  if (filename.startsWith("assets/")) {
    filename = filename.slice("assets/".length);
  }

  return filename;
}

/**
 * The version of Phoenix being run.
 */
function phoenixVersion(): string {
  try {
    const mixExsPath = path.join(process.cwd(), "mix.exs");
    if (fs.existsSync(mixExsPath)) {
      const content = fs.readFileSync(mixExsPath, "utf-8");
      const match = content.match(/version:\s*"([^"]+)"/);
      return match ? match[1] : "unknown";
    }
  } catch {
    // Ignore errors reading mix.exs
  }

  return "unknown";
}

/**
 * The version of the Phoenix Vite plugin being run.
 */
function pluginVersion(): string {
  try {
    const currentDir = path.dirname(new URL(import.meta.url).pathname);
    // Try different paths to find package.json
    const possiblePaths = [
      path.join(currentDir, "../package.json"), // When running from dist/
      path.join(currentDir, "../../package.json"), // When running from src/
    ];

    for (const packageJsonPath of possiblePaths) {
      if (fs.existsSync(packageJsonPath)) {
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath).toString(),
        ) as { version?: string };
        return packageJson.version || "unknown";
      }
    }
  } catch {
    // Ignore errors
  }
  return "unknown";
}

function resolveFullReloadConfig({
  refresh: config,
}: Required<PluginConfig>): PluginOption[] {
  if (typeof config === "boolean") {
    return [];
  }

  if (typeof config === "string") {
    config = [{ paths: [config] }];
  }

  if (!Array.isArray(config)) {
    config = [config];
  }

  if (config.some((c) => typeof c === "string")) {
    config = [{ paths: config }] as RefreshConfig[];
  }

  return (config as RefreshConfig[]).flatMap((c) => {
    const plugin = fullReload(c.paths, c.config);

    /* eslint-disable-next-line @typescript-eslint/ban-ts-comment */
    /** @ts-ignore */
    plugin.__phoenix_plugin_config = c;

    return plugin;
  });
}

export { phoenix };
