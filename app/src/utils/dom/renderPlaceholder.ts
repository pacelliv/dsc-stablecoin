// SPDX-License-Identifier: MIT

import {getDashboardElement} from "./getDashboardElement";

export const renderPlaceholder = () => {
  const dashboard = getDashboardElement();

  dashboard.innerHTML = `
      <div class="dashboard-connect-container">
          <h3 class="dashboard-connect-title">Your wallet is not connected</h3>
          <p class="dashboard-connect-msg">Please, connect your wallet to proceed</p>
          <button
              id="dashboard-connect-btn"
              class="connect-btn inverted"
          >
              Connect wallet
          </button>
      </div>
    `;
};
