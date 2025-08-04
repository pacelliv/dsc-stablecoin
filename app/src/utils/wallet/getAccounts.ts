// SPDX-License-Identifier: MIT

export const getAccounts = async () => {
  const {ethereum} = window;

  try {
    return await ethereum?.request({method: "eth_accounts"});
  } catch (error) {
    throw error;
  }
};
