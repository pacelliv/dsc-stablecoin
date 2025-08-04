// SPDX-License-Identifier: MIT

export const getSpanElement = (id: string) => {
  const span = document.getElementById(id);

  if (!(span instanceof HTMLSpanElement)) {
    throw new Error(`Element with id ${id} not found or is not a <span>.`);
  }

  return span;
};
