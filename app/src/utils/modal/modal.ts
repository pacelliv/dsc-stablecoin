// SPDX-License-Identifier: MIT

import {getDialogElement} from "../dom/getDialogElement";
import {getBodyElement} from "../dom/getBodyElement";
import {disableBodyScroll, enableBodyScroll} from "body-scroll-lock";

export const openModal = (id: string) => {
  const modal = getDialogElement(id);
  const body = getBodyElement();

  disableBodyScroll(body);
  modal.showModal();
  modal.removeAttribute("inert");
  modal.setAttribute("aria-hidden", "false");
  body.setAttribute("inert", "");
};

export const closeModal = (id: string) => {
  const modal = getDialogElement(id);
  const body = getBodyElement();
  const requiredInputs = modal.querySelectorAll("input[required]");
  requiredInputs.forEach((input) => input.removeAttribute("required"));

  enableBodyScroll(body);
  modal.close();
  modal.setAttribute("inert", "");
  modal.setAttribute("aria-hidden", "true");
  body.removeAttribute("inert");
};
