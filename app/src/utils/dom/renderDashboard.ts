// SPDX-License-Identifier: MIT

import {getDashboardElement} from "./getDashboardElement";
import {renderLoader} from "./renderLoader";
import {renderPlaceholder} from "./renderPlaceholder";
import {fetchPositionData} from "../api/fetchPositionData";
import {formatAmount} from "../formatAmount";

export let positionData: UserStats | undefined;

export const renderDashboard = async (account: string) => {
  const dashboard = getDashboardElement();

  try {
    renderLoader("Loading data...");
    positionData = await fetchPositionData(account);
    renderPlaceholder();
  } catch (error) {
    console.error(error);
    renderPlaceholder();
    return;
  }

  const {hFactor, collateral, collateralUsd, debt, borrPower, liqPrice} = positionData;
  const startingPoint = 1;
  const endPoint = 2;
  const range = endPoint - startingPoint;
  let riskPercentage = (parseFloat(hFactor) - startingPoint / range) * 100;

  if (riskPercentage > 100 || parseFloat(hFactor) > 10000) riskPercentage = 100;
  if (riskPercentage < 0) riskPercentage = 0;

  dashboard.innerHTML = `
      <div id="dashboard-wrapper" class="dashboard-wrapper">
        <div class="position-header">
          <h2 class="dashboard-title">Your Vault</h2>
          <div
            class="health-factor ${parseFloat(hFactor) >= 1.5 ? "safety-high" : "safety-low"}"
          >
            Health: ${
              parseFloat(hFactor) > 10000
                ? `10,000+`
                : formatAmount(parseFloat(hFactor), "en-Us", {minimumFractionDigits: 2, maximumFractionDigits: 2})
            }
          </div>
        </div>

        <div>
          <div class="position-grid">
            <div class="metric-box">
              <h3 class="metric-box-title">Collateral</h3>
              <p class="value">${parseFloat(collateral)} ETH</p>
              <p class="subtext">
              ${formatAmount(parseFloat(collateralUsd), "en-Us", {
                currency: "USD",
                style: "currency",
                minimumFractionDigits: 0,
                maximumFractionDigits: 2,
              })}
              </p>
            </div>

            <div class="metric-box">
              <h3 class="metric-box-title">Debt</h3>
              <p class="value">
                ${formatAmount(parseFloat(debt), undefined, {
                  minimumFractionDigits: 0,
                  maximumFractionDigits: 2,
                })} DSC
              </p>
              <p class="subtext">
                ${formatAmount(parseFloat(debt), "en-US", {
                  currency: "USD",
                  style: "currency",
                  minimumFractionDigits: 0,
                  maximumFractionDigits: 2,
                })}
              </p>
            </div>

            <div class="metric-box">
              <h3 class="metric-box-title">Borrowing Power</h3>
              <p class="value">
                ${formatAmount(parseFloat(borrPower), "en-US", {
                  minimumFractionDigits: 0,
                  maximumFractionDigits: 6,
                })} DSC
              </p>
              <p class="subtext">
                ${formatAmount(parseFloat(borrPower), "en-US", {
                  currency: "USD",
                  style: "currency",
                  minimumFractionDigits: 0,
                  maximumFractionDigits: 2,
                })} DSC
              </p>
            </div>

            <div class="metric-box">
              <h3 class="metric-box-title">Liquidation Price</h3>
              <p class="value">
                ${formatAmount(parseFloat(liqPrice), "en-US", {
                  currency: "USD",
                  style: "currency",
                  minimumFractionDigits: 0,
                  maximumFractionDigits: 2,
                })}
              </p>
            </div>
          </div>

          <div class="risk-bar">
            <div class="risk-labels">
                <span>Liquidation (1.0)</span>
                <span>
                  Current (${
                    parseFloat(hFactor) > 10000
                      ? `10,000+`
                      : formatAmount(parseFloat(hFactor), "en-US", {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })
                  })
                </span>
            </div>
            <div class="risk-track">
                <div class="risk-indicator"
                  style="left: ${riskPercentage}%;"
                ></div>
            </div>
          </div>
        </div>

        <div
          id="manage-position-container"
          class="manage-position-container"
        >
          <h2 class="manage-position-title">Manage position</h2>
          <div class="quick-actions">
            <button id="deposit-btn" class="quick-action deposit" data-action="deposit">Deposit</button>
            <button id="mint-btn" class="quick-action mint" data-action="mint">Mint</button>
            <button id="redeem-btn" class="quick-action redeem" data-action="withdraw">Withdraw</button>
            <button id="burn-btn" class="quick-action burn" data-action="burn">Burn</button>
          </div>
          <p class="manage-position-msg">
            Protocol fee: 0% — Update multiple parameters in one
            transaction.
          </p>
        </div>
      </div>
  `;
};
