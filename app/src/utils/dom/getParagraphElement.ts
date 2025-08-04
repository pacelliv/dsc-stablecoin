// SPDX-License-Identifier: MIT

export const getParagraphElement = (id: string) => {
  const paragraph = document.getElementById(id);

  if (!(paragraph instanceof HTMLParagraphElement)) {
    throw new Error(`Element with id ${id} not found or is not a <p>.`);
  }

  return paragraph;
};
