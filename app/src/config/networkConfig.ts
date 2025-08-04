// SPDX-License-Identifier: MIT

export type NetworkConfig = (typeof networksConfig)[number];

export const networksConfig = [
  {
    chainId: 31337,
    name: "Ethereum Anvil",
    rpcUrls: ["http://127.0.0.1:8545"],
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
    blockExplorerUrls: [""],
  },
  {
    chainId: 11155111,
    name: "Ethereum Sepolia",
    rpcUrls: ["https://ethereum-sepolia-rpc.publicnode.com"],
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
    blockExplorerUrls: ["https://sepolia.etherscan.io/"],
  },
  {
    chainId: 421614,
    name: "Arbitrum Sepolia",
    rpcUrls: ["https://arbitrum-sepolia-rpc.publicnode.com"],
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
    blockExplorerUrls: ["https://sepolia.arbiscan.io/"],
  },
] as const;

export const getNetworkConfig = (chainId: number): NetworkConfig => {
  console.log(`target chain id: ${chainId}`);
  const networkConfig = networksConfig.find((config) => config.chainId === chainId);
  if (!networkConfig) {
    throw new Error(`Could not find configuration for chaind ${chainId}`);
  }
  return networkConfig;
};
