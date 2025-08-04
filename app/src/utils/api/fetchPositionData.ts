// SPDX-License-Identifier: MIT

import {getContracts} from "../contract/getContracts";
import type {Eip1193Provider} from "ethers";
import type {BigNumberish} from "ethers";
import {ethers, BrowserProvider} from "ethers";
import {getPriceFeedData} from "../contract/getPriceFeedData";
import {getUsdValue} from "../getUsdValue";

const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;

if (!CHAIN_ID) {
  throw new Error("'CHAIN_ID' environment variable not set");
}

export const toUnits = (value: BigNumberish, units: number) => ethers.formatUnits(value, units);

export const getFloat = (value: bigint, units: number, digits: number) => {
  const valueStr = toUnits(value, units);
  const [integer, decimals] = valueStr.split(".");
  return `${integer}.${decimals.slice(0, digits)}`;
};

export const getPositionInfo = async (address: string): Promise<UserStats> => {
  const {dscEngine} = await getContracts(new BrowserProvider(window.ethereum as Eip1193Provider), CHAIN_ID, false);
  const {_collateralDeposited, _dscMinted, _healthFactor} = (
    await dscEngine.getPositionInfo.staticCall(address)
  ).toObject() as PositionInfo;

  const borrowingPower = await getBorrowingPower(address);
  const liquidationPrice = await getLiquidationPrice(address);
  const collateralUSDValue = await getCollateralUSDValue(_collateralDeposited);

  return {
    hFactor: getFloat(_healthFactor, 18, 2),
    collateral: getFloat(_collateralDeposited, 18, 6),
    collateralUsd: getFloat(collateralUSDValue, 18, 2),
    debt: getFloat(_dscMinted, 18, 6),
    borrPower: getFloat(borrowingPower, 18, 2),
    liqPrice: getFloat(liquidationPrice, 18, 2),
  };
};

const getCollateralUSDValue = async (collateralDeposited: bigint) => {
  const {priceFeed} = await getContracts(new BrowserProvider(window.ethereum as Eip1193Provider), CHAIN_ID, false);
  const {decimals, roundData} = await getPriceFeedData(priceFeed);
  return getUsdValue(collateralDeposited, roundData.answer, decimals);
};

const getBorrowingPower = async (address: string) => {
  const {dscEngine, priceFeed} = await getContracts(
    new BrowserProvider(window.ethereum as Eip1193Provider),
    CHAIN_ID,
    false,
  );
  const positionInfo = (await dscEngine.getPositionInfo.staticCall(address)) as PositionInfo;

  if (positionInfo._collateralDeposited === 0n) {
    return 0n;
  }

  if (parseFloat(getFloat(positionInfo._healthFactor, 18, 2)) <= 1) {
    return 0n;
  }

  const {decimals, roundData} = await getPriceFeedData(priceFeed);
  const collateralUSDValue = getUsdValue(positionInfo._collateralDeposited, roundData.answer, decimals);
  const maxMint = (collateralUSDValue * 50n) / 100n;
  return maxMint - positionInfo._dscMinted;
};

const getLiquidationPrice = async (address: string) => {
  const {dscEngine} = await getContracts(new BrowserProvider(window.ethereum as Eip1193Provider), CHAIN_ID, false);
  const [positionInfo, minimumHealthFactor, precision, liquidationThreshold, liquidationPrecision] = (await Promise.all(
    [
      dscEngine.getPositionInfo.staticCall(address),
      dscEngine.MINIMUM_HEALTH_FACTOR.staticCall(),
      dscEngine.PRECISION.staticCall(),
      dscEngine.LIQUIDATION_THRESHOLD.staticCall(),
      dscEngine.LIQUIDATION_PRECISION.staticCall(),
    ],
  )) as [PositionInfo, bigint, bigint, bigint, bigint];

  if (positionInfo._collateralDeposited === 0n) return 0n;

  const collateralValueAdjustedForThreshold = ((minimumHealthFactor - 1n) * positionInfo._dscMinted) / precision;
  const collateralUsdValue = (collateralValueAdjustedForThreshold * liquidationPrecision) / liquidationThreshold;
  return (collateralUsdValue * precision) / positionInfo._collateralDeposited;
};

export const fetchPositionData = async (account: string) => {
  try {
    return (await getPositionInfo(account)) as UserStats;
  } catch (error) {
    throw error;
  }
};
