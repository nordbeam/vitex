import typescript from "@rollup/plugin-typescript";
import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";

export default {
  input: "src/index.ts",
  output: {
    file: "dist/index.js",
    format: "esm",
    inlineDynamicImports: true,
  },
  external: ["vite", "node:fs", "node:path", "node:net", "fs", "path", "net"],
  plugins: [
    resolve({
      preferBuiltins: true,
      browser: false,
    }),
    commonjs(),
    typescript({
      tsconfig: "./tsconfig.json",
    }),
  ],
};
