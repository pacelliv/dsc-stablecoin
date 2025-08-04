// SPDX-License-Identifier: MIT

export const getDivElement = (id: string) => {
  const div = document.getElementById(id);

  if (!(div instanceof HTMLDivElement)) {
    throw new Error(`Element with id ${id} not found or is not a <div>.`);
  }

  return div;
};
