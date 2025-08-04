// SPDX-License-Identifier: MIT

export const getLabelElement = (id: string) => {
  const label = document.getElementById(id);

  if (!(label instanceof HTMLLabelElement)) {
    throw new Error(`Element with id ${id} not found or is not a <label>.`);
  }

  return label;
};
