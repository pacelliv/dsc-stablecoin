// SPDX-License-Identifier: MIT

export const getDialogElement = (id: string) => {
  const modal = document.getElementById(id);

  if (!(modal instanceof HTMLDialogElement)) {
    throw new Error(`Element with id ${id} not found or is not a <dialog>.`);
  }

  return modal;
};
