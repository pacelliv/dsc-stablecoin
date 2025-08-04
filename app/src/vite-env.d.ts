/// <reference types="vite/client" />

/* eslint no-unused-vars: "off" */
/* eslint @typescript-eslint/no-explicit-any: "off" */

interface Actions {
  primaryAction: string;
  primaryAmount: string;
  primaryAmountUnit: string;
  secondaryAction?: string;
  secondaryAmount?: string;
  secondaryAmountUnit: string;
}

interface Window {
  ethereum?: EIP1193Provider;
}

interface EthereumProviderError extends Error {
  code: number;
  // Add other possible properties if needed
}

// Interface for Ethereum providers based on the EIP-1193 standard.
interface EIP1193Provider {
  // --- Core EIP-1193 Methods ---
  request: (args: {method: string; params?: unknown[]}) => Promise<unknown>; // Standard method for sending requests per EIP-1193

  // --- Optional EIP-1193 Methods ---
  sendAsync?: (
    args: {method: string; params?: unknown[]},
    callback: (error: Error | null, response: unknown) => void,
  ) => void; // For sending asynchronous requests
  send?: (
    args: {method: string; params?: unknown[]},
    callback: (error: Error | null, response: unknown) => void,
  ) => void; // For sending synchronous requests

  // --- Provider Metadata (Wallet-Specific) ---
  isMetaMask?: boolean;
  isStatus?: boolean; // Optional: Indicates the status of the provider
  host?: string; // Optional: Host URL of the Ethereum node
  path?: string; // Optional: Path to a specific endpoint or service on the host

  // --- Connection State ---
  /**
   * Returns true if the provider is connected to its backing node.
   * Note: Does NOT indicate user account access.
   */
  isConnected(): boolean;

  // --- EIP-1193 Events (for completeness) ---
  on(event: string, listener: (...args: any[]) => void): void;
  removeListener?(event: string, listener: (...args: any[]) => void): void;
}

/*//////////////////////////////////////////////////////////////
                          EIP-6963 INTERFACES
    //////////////////////////////////////////////////////////////*/

// Define for future support

// Interface for provider information following EIP-6963.
interface EIP6963ProviderInfo {
  walletId: string; // Unique identifier for the wallet e.g io.metamask, io.metamask.flask
  uuid: string; // Globally unique ID to differentiate between provider sessions for the lifetime of the page
  name: string; // Human-readable name of the wallet
  icon: string; // URL to the wallet's icon
}

// Interface detailing the structure of provider information and its Ethereum provider.
interface EIP6963ProviderDetail {
  info: EIP6963ProviderInfo; // The provider's info
  provider: EIP1193Provider; // The EIP-1193 compatible provider
}

// Type representing the event structure for announcing a provider based on EIP-6963.
type EIP6963AnnounceProviderEvent = {
  detail: {
    info: EIP6963ProviderInfo; // The provider's info
    provider: EIP1193Provider; // The EIP-1193 compatible provider
  };
};

interface ImportMetaEnv {
  VITE_API_BASE_URL: string;
  VITE_DEBUG: string;
  // more env variables...
}

interface UserStats {
  // Health Factor
  hFactor: string;
  // Collateral Deposited
  collateral: string;
  // Collateral Deposited USD Value
  collateralUsd: string;
  // DSC Minted
  debt: string;
  // Borrowing Power
  borrPower: string;
  // Liquidation Price
  liqPrice: string;
}

interface NetworkAddresses {
  ethUsdPriceFeed: string;
  DSC: string;
  DSCEngine: string;
}

type AddressMap = Record<string, string>;

type ContractAddresses = {
  [key: string]: AddressMap;
};

interface AggregatorV3RoundData {
  roundId: bigint;
  answer: bigint;
  startedAt: bigint;
  updatedAt: bigint;
  answeredInRound: bigint;
}

interface LiquidatedEventArgs {
  _liquidator: string;
  _user: string;
  _repaidAmount: bigint;
  _collateralSold: bigint;
}

interface PositionInfo {
  _collateralDeposited: bigint;
  _dscMinted: bigint;
  _healthFactor: bigint;
}
