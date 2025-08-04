// SPDX-License-Identifier: MIT

import type {BigNumberish, EventLog} from "ethers";
import {getUsdValue} from "../getUsdValue";
import {getContracts} from "../contract/getContracts";
import {getPriceFeedData} from "../contract/getPriceFeedData";
import {ethers} from "ethers";
import {getProvider} from "../wallet/getProvider";
import {formatAmount} from "../formatAmount";

export const toUnits = (value: BigNumberish, units: number) => ethers.formatUnits(value, units);

const ALCHEMY_API_KEY = import.meta.env.VITE_ALCHEMY_API_KEY;
const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;
const CACHE_KEY = "protocolStatsCache";
const CACHE_TTL = 2 * 60 * 1000;

if (!ALCHEMY_API_KEY) {
  throw new Error("Env variable `ALCHEMY_API_KEY` not set");
}

if (!CHAIN_ID) {
  throw new Error("Env variable `CHAIN_ID` not set");
}

export const getFloat = (value: bigint, units: number, digits: number) => {
  const valueStr = toUnits(value, units);
  const [integer, decimals] = valueStr.split(".");
  return `${integer}.${decimals.slice(0, digits)}`;
};

export const getTlvUSD = async () => {
  const {dscEngine, priceFeed} = await getContracts(getProvider(CHAIN_ID), CHAIN_ID, false);
  const {decimals, roundData} = await getPriceFeedData(priceFeed);
  const tvlETH = await dscEngine.getTotalDepositedCollateral.staticCall();
  const usdValue = getUsdValue(tvlETH, roundData.answer, decimals);
  return getFloat(usdValue, 18, 2);
};

export const getTlvETH = async () => {
  const {dscEngine} = await getContracts(getProvider(CHAIN_ID), CHAIN_ID, false);
  const tvlETH = (await dscEngine.getTotalDepositedCollateral.staticCall()) as bigint;
  return getFloat(tvlETH, 18, 2);
};

export const getDSCSupply = async () => {
  const {dscEngine} = await getContracts(getProvider(CHAIN_ID), CHAIN_ID, false);
  const dscSupply = (await dscEngine.getDSCSupply.staticCall()) as bigint;
  return getFloat(dscSupply, 18, 2);
};

export const getLiqVol = async () => {
  const blocksPerDay = 7200;
  const provider = getProvider(CHAIN_ID);
  const {dscEngine, priceFeed} = await getContracts(getProvider(CHAIN_ID), CHAIN_ID, false);
  const {decimals, roundData} = await getPriceFeedData(priceFeed);
  const block = await provider.getBlock("latest");

  if (!block) {
    return "0";
  }

  const fromBlock = blocksPerDay > block.number ? 0 : block.number - blocksPerDay;
  const eventFilter = dscEngine.filters.Liquidated();
  const liquidatedEvents = await dscEngine.queryFilter(eventFilter, fromBlock);
  const args = liquidatedEvents
    .filter((event): event is EventLog => Object.hasOwn(event, "args"))
    .map((event) => event.args.toObject() as LiquidatedEventArgs);

  const totalETHLiquidated = args.reduce((acc, current) => acc + current._collateralSold, 0n);
  const usdValue = getUsdValue(totalETHLiquidated, roundData.answer, decimals);
  return getFloat(usdValue, 18, 2);
};

export const getOcRatio = () => {
  return "200%";
};

export const getLiqRatio = () => {
  return "100%";
};

export const fetchProtocolStats = async () => {
  const statsElements = Array.from(document.querySelectorAll(".stat"));
  const cachedProtocolStats = localStorage.getItem(CACHE_KEY);
  const now = Date.now();

  if (cachedProtocolStats) {
    const {data, timestamp} = JSON.parse(cachedProtocolStats);

    if (now - timestamp <= CACHE_TTL) {
      updateStatsElements(statsElements, data);
      return;
    }
  }

  try {
    const data = await Promise.all([
      getTlvUSD(),
      getTlvETH(),
      getDSCSupply(),
      getOcRatio(),
      getLiqRatio(),
      getLiqVol(),
    ]);

    const dataArr = Object.values(data) as string[];

    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({
        data: dataArr,
        timestamp: now,
      }),
    );
    updateStatsElements(statsElements, dataArr);
  } catch (e) {
    console.error(e);
    if (cachedProtocolStats) {
      const {data} = JSON.parse(cachedProtocolStats);
      updateStatsElements(statsElements, data);
    } else {
      updateStatsElements(statsElements, null);
    }
  }
};

const updateStatsElements = (elements: Element[], data: string[] | null) => {
  elements.forEach((el, i) => {
    let value = "-";
    const elClass = el.getAttribute("class");
    el.removeAttribute("aria-busy");
    el.querySelector(".small-loader")?.remove();

    if (elClass && data) {
      if (elClass.includes("tvl-usd") || elClass.includes("liq-vol")) {
        value = formatAmount(parseFloat(data[i]), "en-US", {
          currency: "USD",
          style: "currency",
          notation: "compact",
          minimumFractionDigits: 0,
          maximumFractionDigits: 2,
        });
      } else if (elClass.includes("tvl-eth") || elClass.includes("minted")) {
        value = formatAmount(parseFloat(data[i]), undefined, {
          notation: "compact",
          minimumFractionDigits: 0,
          maximumFractionDigits: 2,
        });
      } else {
        value = data[i];
      }
    }

    el.insertAdjacentHTML("beforeend", `<span class="stat-value">${value}</span>`);
  });
};
