// SPDX-License-Identifier: MIT

import type {Contract} from "ethers";

export const getPriceFeedData = async (priceFeed: Contract) => {
  const [decimals, roundData] = (await Promise.all([
    priceFeed.decimals.staticCall(),
    priceFeed.latestRoundData.staticCall(),
  ])) as [bigint, AggregatorV3RoundData];

  return {decimals, roundData};
};
