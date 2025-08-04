// SPDX-License-Identifier: MIT

import {getDashboardElement} from "./getDashboardElement";

export const renderLoader = (msg: string) => {
  const dashboard = getDashboardElement();

  dashboard.innerHTML = `
      <div class="dashboard-loader-container">
        <div class="big-loader"></div>
        <p id="dashboard-connect-msg" class="dashboard-connect-msg">${msg}</p>
      </div>
    `;
};
