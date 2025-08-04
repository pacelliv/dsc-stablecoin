// SPDX-License-Identifier: MIT

export const getBodyElement = () => {
  const body = document.body;

  if (!body) {
    throw new Error(`Element <body> not found.`);
  }

  return body;
};
