// SPDX-License-Identifier: MIT

export const getSlicedAddress = (addr: string) => {
  return `${addr.slice(0, 5)}...${addr.charAt(38)}...`;
};
