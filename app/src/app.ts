// SPDX-License-Identifier: MIT

import {connect} from "./utils/wallet/connect";
import {renderDashboard} from "./utils/dom/renderDashboard";
import {renderPlaceholder} from "./utils/dom/renderPlaceholder";
import {updateConnectBtn} from "./utils/dom/updateConnectBtn";
import {fetchProtocolStats} from "./utils/api/fetchProtocolStats";
import {setUpScreenResize} from "./utils/dom/updateUIForScreenSize";
import {closeModal} from "./utils/modal/modal";
import {handleTransactionModal} from "./utils/modal/transactionModal";
import {isStatusViewActive, resetTransactionModal} from "./utils/dom/safeRenderTransactionStatusPanel";
import {getDivElement} from "./utils/dom/getDivElement";
import {getParagraphElement} from "./utils/dom/getParagraphElement";
import {getButtonElement} from "./utils/dom/getButtonElement";
import {getInputElement} from "./utils/dom/getInputElement";
import {getLabelElement} from "./utils/dom/getLabelElement";

export let currentAction = "";
export let currentAccount: string | null = null;

document.addEventListener("click", async (event: MouseEvent) => {
  event.stopPropagation();

  const target = event.target as HTMLElement;
  const button = target.closest(
    `
    [id="connect-btn"],
    [id="dashboard-connect-btn"],
    [id="close-error-modal-btn"],
    [id="cancel-btn"],
    [id="deposit-btn"],
    [id="mint-btn"],
    [id="redeem-btn"],
    [id="burn-btn"],
    [id="end-transaction-btn"]
    `,
  );

  if (!button) return;

  const id = button.getAttribute("id");

  if (id === "connect-btn" || id === "dashboard-connect-btn") {
    await connect();
  } else if (id === "close-error-modal-btn" || id === "cancel-btn" || id === "end-transaction-btn") {
    if (id === "end-transaction-btn") {
      await renderDashboard(currentAccount!);
      resetTransactionModal();
    } else if (id === "cancel-btn") {
      getParagraphElement("transaction-form-error-msg").textContent = "";
      getButtonElement("execute-btn").disabled = true;
      getLabelElement("secondary-label").hidden = true;
      getInputElement("secondary-amount-input").hidden = true;
    } else if (isStatusViewActive) {
      getDivElement("action").style.display = "flex";
      getDivElement("action").removeAttribute("inert");
      resetTransactionModal();
    }

    const modal = (button as HTMLButtonElement).dataset.modal as string;
    closeModal(modal);
  } else if (id === "deposit-btn" || id === "mint-btn" || id === "redeem-btn" || id === "burn-btn") {
    const action = (button as HTMLButtonElement).dataset.action;

    if (!action) {
      throw new Error(`Dataset action not set for buttton with id ${id}`);
    }

    currentAction = action;
    handleTransactionModal(action);
  }
});

export const initApp = async () => {
  const {ethereum} = window;

  if (typeof ethereum !== "undefined") {
    await checkConnection(ethereum);

    ethereum.on("accountsChanged", async (accounts: string[]) => {
      const numAccounts = accounts.length;
      if (!numAccounts) {
        currentAccount = null;
        setUpScreenResize(null);
        renderPlaceholder();
      } else if (numAccounts) {
        currentAccount = accounts[0];
        setUpScreenResize(accounts[0]);
        await renderDashboard(accounts[0]);
        updateConnectBtn(accounts[0], numAccounts ? true : false);
      }
    });

    ethereum.on("chainChanged", () => window.location.reload);
  }

  await fetchProtocolStats();
};

const checkConnection = async (ethereum: EIP1193Provider) => {
  const accounts = (await (ethereum as EIP1193Provider).request({
    method: "eth_accounts",
  })) as string[];

  if (!accounts.length) {
    currentAccount = null;
    setUpScreenResize(null);
  } else {
    currentAccount = accounts[0];
    setUpScreenResize(accounts[0]);
    await renderDashboard(accounts[0]);
    updateConnectBtn(accounts[0], true);
  }
};
