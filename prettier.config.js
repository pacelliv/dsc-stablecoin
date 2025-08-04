export default {
  semi: true,
  singleQuote: false,
  tabWidth: 2,
  printWidth: 120,
  trailingComma: "all",
  bracketSpacing: false,
  plugins: ["prettier-plugin-solidity"],
  overrides: [
    {
      files: ["*.js"],
      options: {
        parser: "babel",
      },
    },
    {
      files: "*.sol",
      options: {
        parser: "slang",
        printWidth: 120,
        tabWidth: 4,
        useTabs: false,
        singleQuote: false,
        bracketSpacing: false,
      },
    },
  ],
};
