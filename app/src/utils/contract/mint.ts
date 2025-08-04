// SPDX-License-Identifier: MIT

import {ethers} from "ethers";
import type {Eip1193Provider, TransactionResponse} from "ethers";
import {getContracts} from "./getContracts";
import {safeRenderTransactionStatusPanel} from "../dom/safeRenderTransactionStatusPanel";
import {handleError} from "../lib/handleError";
import {updateTransactionModalForSuccess} from "../modal/transactionModal";

const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;

if (!CHAIN_ID) {
  throw new Error("'CHAIN_ID' environment variable not set");
}

export const mint = async (mintAmount: string) => {
  const {dscEngine} = await getContracts(
    new ethers.BrowserProvider(window.ethereum as Eip1193Provider),
    CHAIN_ID,
    true,
  );

  try {
    const txResponse = (await dscEngine.mint(ethers.parseEther(mintAmount))) as TransactionResponse;
    (document.getElementById("transaction-form") as HTMLFormElement).reset();
    safeRenderTransactionStatusPanel(
      {primaryAction: "mint", primaryAmount: mintAmount, primaryAmountUnit: "DSC"} as Actions,
      txResponse.hash,
    );

    await txResponse.wait(1);
    updateTransactionModalForSuccess();
  } catch (error) {
    handleError(error);
  }
};
