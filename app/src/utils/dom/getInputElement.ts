// SPDX-License-Identifier: MIT

export const getInputElement = (id: string) => {
  const input = document.getElementById(id);

  if (!(input instanceof HTMLInputElement)) {
    throw new Error(`Element with id ${id} not found or is not a <input>.`);
  }

  return input;
};
