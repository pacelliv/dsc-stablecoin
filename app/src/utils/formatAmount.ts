// SPDX-License-Identifier: MIT

export const formatAmount = (
  amount: number | bigint,
  locales: Intl.LocalesArgument,
  options?: Intl.NumberFormatOptions,
) => {
  return new Intl.NumberFormat(locales, options).format(amount);
};
