// SPDX-License-Identifier: MIT

import {getButtonElement} from "../dom/getButtonElement";
import {getCurrentChainId} from "./getCurrentChainId";
import {requestSwitchChain} from "./requestSwitchChain";
import {renderDashboard} from "../dom/renderDashboard";
import {renderPlaceholder} from "../dom/renderPlaceholder";
import {renderLoader} from "../dom/renderLoader";
import {openModal} from "../modal/modal";

const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;

if (!CHAIN_ID) {
  throw new Error("Env variable `VITE_CHAIN_ID` not set");
}

export const connect = async () => {
  const connectBtn = getButtonElement("connect-btn");
  const dashboardConnectBtn = getButtonElement("dashboard-connect-btn");
  let accounts: string[] = [];

  try {
    const {ethereum} = window;

    if (typeof ethereum === "undefined") {
      throw new Error("Could not find MetaMask installed");
    }

    renderLoader("Connecting...");
    connectBtn.disabled = true;
    dashboardConnectBtn.disabled = true;
    accounts = (await ethereum.request({method: "eth_requestAccounts"})) as string[];
    const chainId = (await getCurrentChainId()) as string;

    if (parseInt(chainId, 16) != parseInt(CHAIN_ID)) {
      await requestSwitchChain(parseInt(CHAIN_ID));
    }
  } catch (error) {
    if (error instanceof Error) {
      const errorMsg = document.getElementById("error-msg");

      if (error.message.includes("Could not find MetaMask installed")) {
        errorMsg!.innerHTML = `
          Could not detect MetaMask, please <a 
          href="https://metamask.io/download" 
          target="_blank" 
          class="modal-link" 
          aria-label="Close." 
          >install the extension</a> and try again.
        `;
      } else {
        errorMsg!.innerHTML = "An unknown error has occured, please try again later.";
      }

      openModal("error-modal");
    }
    renderPlaceholder();
  } finally {
    connectBtn.disabled = false;
    dashboardConnectBtn.disabled = false;
    await renderDashboard(accounts[0]);
  }
};
