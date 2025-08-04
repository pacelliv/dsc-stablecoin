// SPDX-License-Identifier: MIT

export const getDashboardElement = () => {
  const dashboardElement = document.getElementById("dashboard");

  if (!(dashboardElement instanceof HTMLElement)) {
    throw new Error(`Element with id dashboard not found or not is a <section>.`);
  }

  return dashboardElement;
};
