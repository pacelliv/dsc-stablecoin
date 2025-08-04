import globals from "globals";
import js from "@eslint/js";
import pluginTypescript from "@typescript-eslint/eslint-plugin";
import parserTypescript from "@typescript-eslint/parser";

export default [
  {
    ignores: [
      "**/node_modules/*",
      "**/dist/*",
      "**/build/*",
      "**/out/*",
      ".env",
      ".env.*",
      "!/.env.example",
      "contracts/broadcast/**",
      "contracts/cache/**",
      "contracts/artifacts/**",
      "contracts/lib/**",
      "**/*.min.js",
      "**/*.min.css",
    ],
  },
  js.configs.recommended,
  {
    files: ["**/*.ts"],
    languageOptions: {
      parser: parserTypescript,
      parserOptions: {
        project: true,
      },
    },
    plugins: {
      "@typescript-eslint": pluginTypescript,
    },
    env: {
      browser: true,
    },
    rules: {
      "@typescript-eslint/no-explicit-any": "warn",
    },
  },
  {
    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.es2021,
        NodeJS: "readonly",
      },
    },
  },
];
