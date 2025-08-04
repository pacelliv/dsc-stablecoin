// SPDX-License-Identifier: MIT

import type {JsonRpcProvider, BrowserProvider} from "ethers";
import DSCEngineABI from "../abis/DSCEngine.json";
import DSCABI from "../abis/DSC.json";
import AggregatorV3Interface from "../abis/AggregatorV3Interface.json";
import {getContractAddress} from "./getContractAddress";
import {ethers} from "ethers";

export const getContracts = async (provider: JsonRpcProvider | BrowserProvider, chainId: string, isWrite: boolean) => {
  return {
    dscEngine: new ethers.Contract(
      getContractAddress(chainId, "DSCEngine"),
      DSCEngineABI,
      isWrite ? await provider.getSigner() : provider,
    ),
    dsc: new ethers.Contract(
      getContractAddress(chainId, "DSC"),
      DSCABI,
      isWrite ? await provider.getSigner() : provider,
    ),
    priceFeed: new ethers.Contract(
      getContractAddress(chainId, "ethUsdPriceFeed"),
      AggregatorV3Interface,
      isWrite ? await provider.getSigner() : provider,
    ),
  };
};
