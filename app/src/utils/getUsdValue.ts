// SPDX-License-Identifier: MIT

export const getUsdValue = (amount: bigint, price: bigint, decimals: bigint) => {
  const normalizedPrice = price * 10n ** (18n - decimals);
  return (amount * normalizedPrice) / (1n * 10n ** 18n);
};
