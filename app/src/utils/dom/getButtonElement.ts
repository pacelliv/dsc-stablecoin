// SPDX-License-Identifier: MIT

export const getButtonElement = (id: string) => {
  const button = document.getElementById(id);

  if (!(button instanceof HTMLButtonElement)) {
    throw new Error(`Element with id ${id} not found or is not a <button>.`);
  }

  return button;
};
