// SPDX-License-Identifier: MIT

import {openModal} from "./modal";
import {positionData} from "../dom/renderDashboard";
import {getParagraphElement} from "../dom/getParagraphElement";
import {getSpanElement} from "../dom/getSpanElement";
import {formatAmount} from "../formatAmount";
import {getButtonElement} from "../dom/getButtonElement";
import {getInputElement} from "../dom/getInputElement";
import {getLabelElement} from "../dom/getLabelElement";
import {deposit} from "../contract/deposit";
import {depositAndMint} from "../contract/depositAndMint";
import {mint} from "../contract/mint";
import {currentAction} from "../../app";
import {burnAndRedeem} from "../contract/burnAndRedeem";
import {burn} from "../contract/burn";
import {redeem} from "../contract/redeem";
import {coverLoader} from "../dom/safeRenderTransactionStatusPanel";

interface Amounts {
  primaryAmount?: string;
  secondaryAmount?: string;
}

export let amounts: Amounts = {};

document.addEventListener("submit", async (event) => {
  event.preventDefault();

  const form = event.target as HTMLFormElement;
  const submitter = event.submitter as HTMLButtonElement;
  const formData = new FormData(form);
  const primaryAmount = formData.get("primary-amount-input")?.toString();
  const secondaryAmount = formData.get("secondary-amount-input")?.toString();

  if (submitter.name === "submit-form-btn") {
    getParagraphElement("transaction-form-error-msg").textContent = "";
    getButtonElement("execute-btn").disabled = true;

    if (currentAction === "deposit") {
      secondaryAmount ? await depositAndMint(primaryAmount!, secondaryAmount) : await deposit(primaryAmount!);
    } else if (currentAction === "mint") {
      secondaryAmount ? await depositAndMint(secondaryAmount, primaryAmount!) : await mint(primaryAmount!);
    } else if (currentAction === "withdraw") {
      secondaryAmount ? await burnAndRedeem(secondaryAmount, primaryAmount!) : await redeem(primaryAmount!);
    } else if (currentAction === "burn") {
      secondaryAmount ? await burnAndRedeem(primaryAmount!, secondaryAmount) : await burn(primaryAmount!);
    }
  }
});

document.addEventListener("input", () => {
  const option = getInputElement("option");
  const primaryInput = getInputElement("primary-amount-input");
  const secondaryInput = getInputElement("secondary-amount-input");

  if (option.checked) {
    getLabelElement("secondary-label").hidden = false;
    getInputElement("secondary-amount-input").hidden = false;
  } else {
    getLabelElement("secondary-label").hidden = true;
    getInputElement("secondary-amount-input").hidden = true;
  }

  if (!primaryInput.value && !secondaryInput.value) {
    getButtonElement("execute-btn").disabled = true;
    getSpanElement("action-required").textContent = "Please, fill the form";
  } else {
    amounts.primaryAmount = primaryInput.value;
    amounts.secondaryAmount = secondaryInput.value;
    getButtonElement("execute-btn").disabled = false;
    getSpanElement("action-required").textContent = "Please, confirm the transaction";
  }
});

const renderTransactionModalStats = (data = positionData) => {
  if (!data) return;

  getInputElement("option").checked = false;

  const collateralAmount = getParagraphElement("col-amount");
  const debtAmount = getParagraphElement("debt-amount");
  const healthAmount = getParagraphElement("health-amount");
  const healthFactor = parseFloat(data.hFactor);

  if (healthFactor < 1) {
    healthAmount.style.color = "#dc2626";
  } else {
    healthAmount.style.color = "#166534";
  }

  collateralAmount.textContent = formatAmount(parseFloat(data.collateral), "en-Us", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  debtAmount.textContent = formatAmount(parseFloat(data.debt), "en-Us", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  healthAmount.textContent =
    "+" +
    formatAmount(healthFactor > 10000 ? 10000 : healthFactor, "en-Us", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });
};

export const handleTransactionModal = (action: string) => {
  if (!positionData) return;

  getLabelElement("secondary-label").hidden = true;
  getInputElement("secondary-amount-input").hidden = true;
  const transactionType = getParagraphElement("transaction-type");
  const primarySpan = getSpanElement("primary-span");
  const secondarySpan = getSpanElement("secondary-span");
  const txAction = getSpanElement("tx-action");

  switch (action) {
    case "deposit":
      transactionType.textContent = "Deposit";
      txAction.textContent = "Mint";
      primarySpan.textContent = "deposit";
      secondarySpan.textContent = "mint";
      break;

    case "mint":
      transactionType.textContent = "Mint";
      txAction.textContent = "Deposit";
      primarySpan.textContent = "mint";
      secondarySpan.textContent = "deposit";
      break;

    case "burn":
      transactionType.textContent = "Burn";
      txAction.textContent = "Withdraw";
      primarySpan.textContent = "burn";
      secondarySpan.textContent = "withdraw";
      break;

    case "withdraw":
      transactionType.textContent = "Withdraw";
      txAction.textContent = "Burn";
      primarySpan.textContent = "withdraw";
      secondarySpan.textContent = "burn";
      break;

    default:
      throw new Error(`Action ${action} is invalid`);
  }

  getParagraphElement("transaction-status").textContent = "";
  renderTransactionModalStats();
  openModal("transaction-modal");
};

export const updateTransactionModalForSuccess = () => {
  coverLoader(false);
  getParagraphElement("transaction-status").textContent = "Transaction confirmed";
  getButtonElement("end-transaction-btn").disabled = false;
};
