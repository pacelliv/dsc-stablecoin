// SPDX-License-Identifier: MIT

import {getNetworkConfig} from "../../config/networkConfig";

const toHex = (num: number) => `0x${num.toString(16)}`;

export const requestSwitchChain = async (chainID: number) => {
  const {ethereum} = window;

  if (!ethereum) return;

  try {
    await ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{chainId: toHex(chainID)}],
    });
  } catch (error) {
    const switchError = error as EthereumProviderError;

    if (switchError.code === 4902) {
      const {name, chainId, rpcUrls, blockExplorerUrls, nativeCurrency} = getNetworkConfig(chainID);

      try {
        await ethereum.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: toHex(chainId),
              chainName: name,
              rpcUrls: rpcUrls,
              nativeCurrency: nativeCurrency,
              blockExplorerUrls: blockExplorerUrls,
            },
          ],
        });
      } catch (addError) {
        throw addError;
      }
    }
  }
};
