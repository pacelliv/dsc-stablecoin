// SPDX-License-Identifier: MIT

import {getButtonElement} from "./getButtonElement";
import {getSlicedAddress} from "../wallet/getSlicedAddress";

export const updateConnectBtn = (address: string, isConnected: boolean) => {
  const connectBtn = getButtonElement("connect-btn");

  connectBtn.innerHTML = `
      <img 
        src="/MetaMask-Logo-Pack/MetaMask/MetaMask-icon-fox.svg"
        alt="MetaMask"
        width="22"
        height="22"
      />
      <span class="connect-btn-text">${isConnected ? getSlicedAddress(address) : "Connect wallet"}</span>
    `;
};
