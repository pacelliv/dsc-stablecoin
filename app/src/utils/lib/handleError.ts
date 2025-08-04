// SPDX-License-Identifier: MIT

import {isError} from "ethers";
import {getParagraphElement} from "../dom/getParagraphElement";
import {getButtonElement} from "../dom/getButtonElement";

export const handleError = (error: unknown) => {
  if (isError(error, "CALL_EXCEPTION")) {
    getButtonElement("execute-btn").disabled = false;
    const errorShortMessage = error.shortMessage;
    const errorData = errorShortMessage.includes("missing revert data") ? error.transaction.data : error.data;

    if (errorData === "0xd0e30db0") {
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Insufficient funds.";
    } else if (errorData === "0xcd80f490") {
      // DSCEngine__BrokenHealthFactor
      getParagraphElement("transaction-form-error-msg").textContent =
        "Error: these amounts will break your health factor.";
    } else if (errorData === "0x8ae84d91") {
      // DSCEngine__InsufficientBalance
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Insufficient funds.";
    } else if (errorData === "0x1f38ea1c") {
      // DSCEngine__InsufficientDebt
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Insufficient DSC balance.";
    } else if (errorData === "0x52630dcd") {
      // DSCEngine__RedeemFailed
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Withdrawal failed.";
    } else if (errorData === "0x1dda5b64") {
      // DSCEngine__TransferFromFailed
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Burn failed.";
    } else if (errorData === "0x89680208") {
      // DSCEngine__UserCannotBeLiquidated
      getParagraphElement("transaction-form-error-msg").textContent = "";
    } else if (errorData === "0x3b6e1736") {
      // DSCEngine__ZeroAmount
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Cannot use zero amounts.";
    } else if (errorData === "0xc4a1093a") {
      // OracleLib__StalePrice
      getParagraphElement("transaction-form-error-msg").textContent = "Error: Oracle problem.";
    }
  } else if (isError(error, "ACTION_REJECTED")) {
    getButtonElement("execute-btn").disabled = false;
  } else if (error instanceof Error) {
    console.error(error);
    if (error.message.includes("Error: Insufficient DSC balance.")) {
      getButtonElement("execute-btn").disabled = false;
      getParagraphElement("transaction-form-error-msg").textContent = error.message;
    }
  } else {
    console.error("Error is not a CALL_EXCEPTION");
    console.error(error);
  }
};
