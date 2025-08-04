// SPDX-License-Identifier: MIT

import addresses from "../addresses/addresses.json";

export const getContractAddress = (chainId: string, name: keyof NetworkAddresses) => {
  const chain: NetworkAddresses = addresses[parseInt(chainId).toString() as keyof typeof addresses];

  if (!chain) {
    throw new Error(`Network configuration for chain id ${chainId} not found`);
  }

  const contractAddress = chain[name];

  if (!contractAddress) {
    throw new Error(`Contract ${name} no found in configuration for chain ${chainId}`);
  }

  return contractAddress;
};
