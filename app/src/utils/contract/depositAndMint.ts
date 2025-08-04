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

export const depositAndMint = async (depositAmount: string, mintAmount: string) => {
  const {dscEngine} = await getContracts(
    new ethers.BrowserProvider(window.ethereum as Eip1193Provider),
    CHAIN_ID,
    true,
  );

  try {
    const txResponse = (await dscEngine.depositAndMint(ethers.parseEther(mintAmount), {
      value: ethers.parseEther(depositAmount),
    })) as TransactionResponse;

    getParagraphElement("transaction-type").textContent = "Deposit and Mint";
    (document.getElementById("transaction-form") as HTMLFormElement).reset();
    safeRenderTransactionStatusPanel(
      {
        primaryAction: "deposit",
        primaryAmount: depositAmount,
        primaryAmountUnit: "ETH",
        secondaryAction: "mint",
        secondaryAmount: mintAmount,
        secondaryAmountUnit: "DSC",
      } as Actions,
      txResponse.hash,
    );
    await txResponse.wait(1);
    updateTransactionModalForSuccess();
  } catch (error) {
    handleError(error);
  }
};
