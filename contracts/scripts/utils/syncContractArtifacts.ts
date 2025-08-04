import fs from "node:fs/promises";
import path from "node:path";
import {ethers} from "ethers";

type FoundryTransaction = {
  hash?: string;
  transactionType?: string;
  contractName?: string;
  contractAddress?: string;
  function?: null;
  arguments?: string[];
  transaction?: {
    from?: string;
    gas?: string;
    value?: string;
    input?: string;
    nonce?: string;
    chainId?: string;
  };
  additionalContracts?: string[];
  isFixedGasLimit?: boolean;
};

type ReturnItem = {
  internal_type: string;
  value: string;
};

type ReturnsObject = {
  [key: string]: ReturnItem;
};

type FoundryBroadcast = {
  transactions: FoundryTransaction[];
  receipts?: null; // I need to work on this :)
  libraries: string[];
  pending: string[];
  returns: ReturnsObject;
  timestamp: number;
  chain: number;
  commit: null;
};

export type FoundryArtifact = {
  abi?: ABI[];
  bytecode: string;
  deployedBytecode: string;
  metadata?: Record<string, unknown>;
};

type ABIFunction = {
  type: "function" | "constructor" | "fallback" | "receive";
  name?: string;
  inputs: Array<{
    name: string;
    type: string;
    internalType?: string;
    components?: ABIFunction["inputs"]; // For tuples
  }>;
  outputs?: ABIFunction["inputs"];
  stateMutability?: "pure" | "view" | "nonpayable" | "payable";
};

type ABIEvent = {
  type: "event";
  name: string;
  inputs: Array<{
    name: string;
    type: string;
    indexed: boolean;
    internalType?: string;
    components?: ABIEvent["inputs"];
  }>;
  anonymous?: boolean;
};

type ABIError = {
  type: "error";
  name: string;
  inputs: Array<{
    name: string;
    type: string;
    internalType?: string;
    components?: ABIError["inputs"];
  }>;
};

export type ABI = Array<ABIFunction | ABIEvent | ABIError | {type: string}>; // Catch-all for other ABI types

interface DirectoriesPathResult {
  abisDirPath: string;
  addressesDirPath: string;
}

interface ContractPath {
  name: string;
  dest: string;
}

interface FilesPathResult {
  addressesFilePath: string;
  contractsFilesPath: ContractPath[];
}

const __dirname = import.meta.dirname;
const contracts = ["AggregatorV3Interface", "MockV3Aggregator", "DSC", "DSCEngine"];
const basePathToApp = path.join(__dirname, "..", "..", "..", "app", "src", "utils");
const basePaths = [basePathToApp];

const getABI = async (contractName: string) => {
  const artifactsPath = path.join("out", `${contractName}.sol`, `${contractName}.json`);
  try {
    const artifacts: FoundryArtifact = JSON.parse(await fs.readFile(artifactsPath, {encoding: "utf8"}));

    if (!Array.isArray(artifacts.abi)) {
      throw new Error(`ABI not found or invalid in ${contractName}.json`);
    }

    return artifacts.abi;
  } catch (error) {
    const fsError = error as NodeJS.ErrnoException;
    if (fsError.code === "ENOENT") return false;
    throw new Error(`Failed to get artifacts for ${contractName} at ${artifactsPath}: ${fsError.message}`);
  }
};

const getTransactions = async () => {
  const chainId = getChainIdFromCLI();
  const transactionsPath = path.join("broadcast", "DeploySystem.s.sol", `${chainId}`, "run-latest.json");

  try {
    const broadcast: FoundryBroadcast = JSON.parse(await fs.readFile(transactionsPath, {encoding: "utf8"}));

    if (!Array.isArray(broadcast.transactions)) {
      throw new Error(`Transactions not found or invalid in ${transactionsPath}`);
    }

    return broadcast.transactions;
  } catch (error) {
    const fsError = error as NodeJS.ErrnoException;
    // if (fsError.code === "ENOENT") return false;
    throw new Error(`Failed to get transactions for chain ${chainId} at ${transactionsPath}: ${fsError.message}`);
  }
};

const exists = async (path: string, type: "directory" | "file") => {
  try {
    const stats = await fs.stat(path);
    return type === "directory" ? stats.isDirectory() : stats.isFile();
  } catch (error) {
    const fsError = error as NodeJS.ErrnoException;
    if (fsError.code === "ENOENT") return false;
    throw new Error(`Failed to check existence of ${type} at ${path}: ${fsError.message}`);
  }
};

const createDir = async (dest: string) => {
  try {
    await fs.mkdir(dest, {recursive: true});
  } catch (error) {
    const fsError = error as NodeJS.ErrnoException;
    if (fsError.code !== "EEXIST") {
      throw new Error(`Failed to create directory in ${dest}: ${fsError.message}`);
    }
  }
};

const getDirectoriesPath = async (basePath: string): Promise<DirectoriesPathResult> => {
  try {
    const abisDirPath = path.join(basePath, "abis");
    const addressesDirPath = path.join(basePath, "addresses");

    const [abisDirExists, addressesDirExists] = await Promise.all([
      exists(abisDirPath, "directory"),
      exists(addressesDirPath, "directory"),
    ]);

    return {
      abisDirPath: !abisDirExists ? abisDirPath : "",
      addressesDirPath: !addressesDirExists ? addressesDirPath : "",
    };
  } catch (error) {
    throw new Error(
      `Failed to check directories in ${basePath}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
};

const getFilesPath = (basePath: string): FilesPathResult => {
  try {
    const addressesFilePath = path.join(basePath, "addresses", "addresses.json");
    const contractFilesPaths = contracts.map((contract) => {
      return {
        name: contract,
        dest: path.join(basePath, "abis", `${contract}.json`),
      };
    });

    return {
      addressesFilePath: addressesFilePath,
      contractsFilesPath: contractFilesPaths,
    };
  } catch (error) {
    throw new Error(
      `Failed to check directories in ${basePath}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
};

const updateABIs = async (pathObj: ContractPath) => {
  try {
    const abi = await getABI(pathObj.name);
    await fs.writeFile(pathObj.dest, JSON.stringify(abi, null, 2));
  } catch (error) {
    throw new Error(
      `Failed to update ABI in ${pathObj.dest}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
};

const getAddressesObj = async (filePath: string) => {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (error) {
    const fsError = error as NodeJS.ErrnoException;
    if (fsError.code === "ENOENT") return {};
    throw new Error(
      `Failed to get addresses file in ${filePath}: ${fsError instanceof Error ? fsError.message : String(fsError)}`,
    );
  }
};

const getChainIdFromCLI = (): string => {
  const chainIdIndex = process.argv.findIndex((arg) => arg === "--chain-id");

  if (chainIdIndex === -1) {
    throw new Error("Missing --chain-id argument");
  }

  const chainId = process.argv[chainIdIndex + 1];

  if (!chainId || isNaN(Number(chainId))) {
    throw new Error("Invalid chain ID provided");
  }

  return chainId;
};

const updateAddresses = async (filePath: string) => {
  const chainId = getChainIdFromCLI();
  const addressesObj = await getAddressesObj(filePath);
  const transactions = await getTransactions();

  const txObj = ["DSCEngine", "DSC"].map((contract) => {
    const transaction = transactions.find((tx) => tx.contractName === contract && tx.transactionType === "CREATE");
    return [contract, transaction ? transaction.contractAddress : ""];
  });

  addressesObj[chainId] = Object.fromEntries(txObj);

  const provider = new ethers.JsonRpcProvider(
    chainId === "31337" ? "http://127.0.0.1:8545" : "https://ethereum-sepolia-rpc.publicnode.com",
  );

  const IDSCEngine = new ethers.Interface(["function getPriceFeed() external view returns (address)"]);

  addressesObj[chainId]["ethUsdPriceFeed"] = await new ethers.Contract(
    addressesObj[chainId]["DSCEngine"],
    IDSCEngine,
    provider,
  ).getPriceFeed();

  try {
    await fs.writeFile(filePath, JSON.stringify(addressesObj, null, 2));
  } catch (error) {
    throw new Error(
      `Failed to update addresses in ${filePath}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
};

const syncContractArtifacts = async () => {
  try {
    console.log("\n==========================");
    console.log("\n⌛ Syncing ABIs and addresses...");
    await Promise.all(
      basePaths.map(async (basePath) => {
        try {
          const {abisDirPath, addressesDirPath} = await getDirectoriesPath(basePath);

          if (abisDirPath) {
            await createDir(abisDirPath);
          }

          if (addressesDirPath) {
            await createDir(addressesDirPath);
          }

          const {addressesFilePath, contractsFilesPath} = getFilesPath(basePath);

          await updateAddresses(addressesFilePath);

          // for (const pathObj of contractsFilesPath) {
          //   await updateABIs(pathObj);
          // }
        } catch (error) {
          throw new Error(
            `Failed to process base path ${basePath}: ${error instanceof Error ? error.message : String(error)}`,
          );
        }
      }),
    );
    console.log("\n✅ Artifacts synced!\n");
  } catch (error) {
    console.error("Error in syncContractArtifacts:", error instanceof Error ? error.message : String(error));
    // Re-throw or handle as needed
    throw error;
  }
};

syncContractArtifacts()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Fatal error in script execution:", error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
