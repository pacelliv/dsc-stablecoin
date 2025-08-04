// SPDX-License-Identifier: MIT

import {getDivElement} from "./getDivElement";
import {getParagraphElement} from "./getParagraphElement";

export let isStatusViewActive = false;
let originalLoaderHTML = "";
let originalFormHTML = "";

document.addEventListener("DOMContentLoaded", () => {
  originalFormHTML = getDivElement("transaction-container").innerHTML;
});

export const resetTransactionModal = () => {
  const container = getDivElement("transaction-container");
  container.innerHTML = originalFormHTML;
};

export const coverLoader = (pending: boolean) => {
  const loaderBackground = document.getElementById("loader-background");
  const loaderSVG = document.getElementById("loader-svg-3");

  if (!loaderBackground || !loaderSVG) {
    return;
  }

  const backgroundRect = loaderBackground.getBoundingClientRect();
  const loaderSVGRect = loaderSVG.getBoundingClientRect();
  const styleElement = document.createElement("style");
  document.head.appendChild(styleElement);

  for (const child of loaderBackground.children) {
    if (!pending) {
      if (child.id === "dot-3" || child.id === "dot-4") {
        child.innerHTML = `
          <svg class="svg confirmed" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><path fill="currentColor" d="m9 19.414l-6.707-6.707l1.414-1.414L9 16.586L20.293 5.293l1.414 1.414z"/></svg>
          <p>${child.id === "dot-3" ? "Waiting for confirmation" : "Transaction confirmed"}</p>
          `;
      }
    }
  }

  const percentage = pending ? ((loaderSVGRect.left - backgroundRect.left) / backgroundRect.width) * 100 : 100;

  styleElement.innerHTML = `
    .loader-background::before {
        width: ${percentage}%;
    }
    `;
};

export const safeRenderTransactionStatusPanel = (actions: Actions, txHash: string) => {
  renderTransactionStatusPanel(actions, txHash);
  isStatusViewActive = true;
};

export const renderTransactionStatusPanel = (actions: Actions, txHash: string) => {
  getDivElement("action").style.display = "none";
  getDivElement("action").setAttribute("inert", "");
  getParagraphElement("transaction-status").textContent = "Wainting for confirmation...";
  const container = getDivElement("transaction-container");

  if (!originalLoaderHTML) {
    originalLoaderHTML = document.querySelector(".loader-background")?.innerHTML || "";
  }

  container.innerHTML = `
        <div>
            <div id="loader-background" class="loader-background">
                <div id="dot-1" class="dot-loader">
                    <svg class="svg confirmed" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><path fill="currentColor" d="m9 19.414l-6.707-6.707l1.414-1.414L9 16.586L20.293 5.293l1.414 1.414z"/></svg>
                    <p>Insert amounts</p>
                </div>
                <div id="dot-2" class="dot-loader">
                    <svg class="svg confirmed" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><path fill="currentColor" d="m9 19.414l-6.707-6.707l1.414-1.414L9 16.586L20.293 5.293l1.414 1.414z"/></svg>
                    <p>Initiate transaction</p>
                </div>
                <div id="dot-3" class="dot-loader">
                    <svg class="svg pending" id="loader-svg-3" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><circle cx="4" cy="12" r="3" fill="#5823f3"><animate id="svgSpinners3DotsFade0" fill="freeze" attributeName="opacity" begin="0;svgSpinners3DotsFade1.end-0.25s" dur="0.75s" values="1;0.2"/></circle><circle cx="12" cy="12" r="3" fill="#5823f3" opacity="0.4"><animate fill="freeze" attributeName="opacity" begin="svgSpinners3DotsFade0.begin+0.15s" dur="0.75s" values="1;0.2"/></circle><circle cx="20" cy="12" r="3" fill="#5823f3" opacity="0.3"><animate id="svgSpinners3DotsFade1" fill="freeze" attributeName="opacity" begin="svgSpinners3DotsFade0.begin+0.3s" dur="0.75s" values="1;0.2"/></circle></svg>
                    <p>Waiting for confirmation</p>
                </div>
                <div id="dot-4" class="dot-loader">
                    <svg class="svg pending" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><circle cx="4" cy="12" r="3" fill="#5823f3"><animate id="svgSpinners3DotsFade0" fill="freeze" attributeName="opacity" begin="0;svgSpinners3DotsFade1.end-0.25s" dur="0.75s" values="1;0.2"/></circle><circle cx="12" cy="12" r="3" fill="#5823f3" opacity="0.4"><animate fill="freeze" attributeName="opacity" begin="svgSpinners3DotsFade0.begin+0.15s" dur="0.75s" values="1;0.2"/></circle><circle cx="20" cy="12" r="3" fill="#5823f3" opacity="0.3"><animate id="svgSpinners3DotsFade1" fill="freeze" attributeName="opacity" begin="svgSpinners3DotsFade0.begin+0.3s" dur="0.75s" values="1;0.2"/></circle></svg>
                    <p>Transaction confirmed</p>
                </div>
            </div>    
            <h3 class="confirmation-title">Wainting for confirmation</h3>
            <div id="transaction-details" class="transaction-details">
                <div>
                    <h4 class="confirmaton-sub-title">${actions.primaryAction}</h4>
                    <p>${actions.primaryAmount} ${actions.primaryAmountUnit}</p>
                </div>
                ${
                  actions.secondaryAction
                    ? `
                <div>
                  <h4 class="confirmaton-sub-title">${actions.secondaryAction}</h4>
                  <p>${actions.secondaryAmount} ${actions.secondaryAmountUnit}</p>
                </div>`
                    : ""
                }
                <div>
                    <h4 class="confirmaton-sub-title">Transaction Hash</h4>
                    <p>
                        <a 
                            href="https://sepolia.etherscan.io/tx/${txHash}"
                            target="_blank"
                        >
                            ${txHash}
                        </a>
                    </p>
                </div>
            </div>
        </div>

        <div class="transaction-modal-buttons-container">
            <button id="end-transaction-btn" class="cancel-btn" data-modal="transaction-modal" disabled>
                <span>Close</span>
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
                    <path
                        fill="currentColor"
                        d="M19 4h-3.5l-1-1h-5l-1 1H5v2h14M6 19a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7H6z"
                    />
                </svg>
            </button>
        </div>
    `;

  coverLoader(true);
};
