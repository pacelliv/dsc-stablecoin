// SPDX-License-Identifier: MIT

export const getCurrentChainId = async () => {
  const {ethereum} = window;

  if (!ethereum) return;

  try {
    return ethereum.request({method: "eth_chainId"});
  } catch (error) {
    throw error;
  }
};
