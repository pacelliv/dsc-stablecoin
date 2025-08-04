// SPDX-License-Identifier: MIT

import {JsonRpcProvider} from "ethers";

export const getProvider = (chainId: string) => {
  let rpcUrl: string;

  switch (chainId) {
    case "11155111":
      rpcUrl = process.env.ETHEREUM_SEPOLIA_RPC_URL || "https://ethereum-sepolia-rpc.publicnode.com";
      break;
    default:
      rpcUrl = "http://127.0.0.1:8545";
      break;
  }

  return new JsonRpcProvider(rpcUrl);
};
