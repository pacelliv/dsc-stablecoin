// SPDX-License-Identifier: MIT

import {getButtonElement} from "./getButtonElement";
import {getSlicedAddress} from "../wallet/getSlicedAddress";

let currentAccount: string | null = null;

const media = window.matchMedia("(min-width: 950px)");

const updateUIForScreenSize = (e: MediaQueryListEvent | MediaQueryList) => {
  const connectBtn = getButtonElement("connect-btn");

  if (currentAccount) {
    const addressElement = document.querySelector(".connect-btn-text");

    if (addressElement) {
      addressElement.textContent = getSlicedAddress(currentAccount);
    }
  } else if (e.matches) {
    // for screen size >= 950px
    connectBtn.textContent = "Connect wallet";
  } else {
    // for screen size < 950px
    connectBtn.textContent = "Connect";
  }
};

media.addEventListener("change", updateUIForScreenSize);

export const setUpScreenResize = (account: string | null) => {
  currentAccount = account;
  updateUIForScreenSize(media);
};
