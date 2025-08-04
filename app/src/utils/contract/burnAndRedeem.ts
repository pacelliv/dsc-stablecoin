// SPDX-License-Identifier: MIT

import {getContracts} from "./getContracts";
import type {Eip1193Provider, TransactionResponse} from "ethers";
import {ethers} from "ethers";
import {getParagraphElement} from "../dom/getParagraphElement";
import {safeRenderTransactionStatusPanel} from "../dom/safeRenderTransactionStatusPanel";
import {handleError} from "../lib/handleError";
import {updateTransactionModalForSuccess} from "../modal/transactionModal";

const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;

if (!CHAIN_ID) {
  throw new Error("'CHAIN_ID' environment variable not set");
}

export const burnAndRedeem = async (burnAmount: string, redeemAmount: string) => {
  const {dsc, dscEngine} = await getContracts(
    new ethers.BrowserProvider(window.ethereum as Eip1193Provider),
    CHAIN_ID,
    true,
  );

  try {
    await (await dsc.approve(await dscEngine.getAddress(), ethers.parseEther(burnAmount))).wait(1);

    const burnAndRedeemTxResponse = (await dscEngine.burnAndRedeem(
      ethers.parseEther(burnAmount),
      ethers.parseEther(redeemAmount),
    )) as TransactionResponse;

    getParagraphElement("transaction-type").textContent = "Burn and Redeem";
    (document.getElementById("transaction-form") as HTMLFormElement).reset();
    safeRenderTransactionStatusPanel(
      {
        primaryAction: "burn",
        primaryAmount: burnAmount,
        primaryAmountUnit: "DSC",
        secondaryAction: "withdraw",
        secondaryAmount: redeemAmount,
        secondaryAmountUnit: "ETH",
      } as Actions,
      burnAndRedeemTxResponse.hash,
    );
    await burnAndRedeemTxResponse.wait(1);
    updateTransactionModalForSuccess();
  } catch (error) {
    handleError(error);
  }
};
