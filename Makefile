# Makefile for Decentralized Stablecoin (DSC) project

-include contracts/.env

.PHONY: all clean reset install-app install-contracts install help server app compile build-app deploy test-contracts format anvil update-price get-latest-price get-latest-round get-round-data deposit mint deposit-and-mint redeem burn burn-and-redeem liquidate get-position-info get-price-feed get-dsc get-total-collateral get-dsc-supply setup-mock-users

# =============================================================
# Deployment Configuration
# =============================================================

# --- Defaults (Anvil) ---

DEFAULT_ANVIL_SENDER := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL = http://127.0.0.1:8545
PRIVATE_KEY ?= $(DEFAULT_ANVIL_PRIVATE_KEY)
DEPLOYMENT_NETWORK_FLAGS = --private-key $(PRIVATE_KEY)
TRANSACTION_NETWORK_FLAGS = --private-key $(PRIVATE_KEY)

# --- Testnet Config ---
DEFAULT_DEV_EVM_SENDER := 0xCc8188e984b4C392091043CAa73D227Ef5e0d0a7
KEYSTORE_ACCOUNT ?= dev0
SENDER ?= $(DEFAULT_DEV_EVM_SENDER)
TESTNET_DEPLOYMENT_FLAGS := --sender $(SENDER) --account $(KEYSTORE_ACCOUNT) --verify --etherscan-api-key $(ETHERSCAN_API_KEY)
TESTNET_TRANSACTION_FLAGS := --account $(KEYSTORE_ACCOUNT)

# --- Deployment Network Selection ---
ifeq ($(findstring ethSepolia,$(NETWORK)), ethSepolia)
	RPC_URL = $(ETHEREUM_SEPOLIA_RPC_URL)
	DEPLOYMENT_NETWORK_FLAGS = $(TESTNET_DEPLOYMENT_FLAGS)
	TRANSACTION_NETWORK_FLAGS = $(TESTNET_TRANSACTION_FLAGS)
else ifeq ($(findstring arbSepolia,$(NETWORK)), arbSepolia)
	RPC_URL = $(ARBITRUM_SEPOLIA_RPC_URL)
	DEPLOYMENT_NETWORK_FLAGS = $(TESTNET_DEPLOYMENT_FLAGS)
	TRANSACTION_NETWORK_FLAGS = $(TESTNET_TRANSACTION_FLAGS)
endif

# --- Dynamic Chain ID ---
CHAIN_ID = $$(cast chain-id --rpc-url $(RPC_URL))

# =============================================================
# Targets
# =============================================================

# Default target
all: clean reset install

# Help target (optional but useful)
help:
	@echo "Available targets:"
	@echo "  all					- Clean, reset and install everything."
	@echo "  clean					- Clean build artifacts."
	@echo "  reset					- Reset git submodules."
	@echo "  install				- Install all dependencies."
	@echo "  app					- Start frontend."
	@echo "  build-app				- Build app webpage."
	@echo "  deploy					- Deploy contracts."
	@echo "  test-contracts			- Run contract tests."
	@echo "  format					- Format all code."
	@echo "  anvil					- Starts Anvil blockchain."
	@echo "  compile				- Compiles the smart contracts."
	@echo "  update-price			- Updates the price of the mock price feed."
	@echo "  update-round-data		- Updates round data in mock price feed."
	@echo "  get-latest-price		- Reads the last posted price in the mock."
	@echo "  get-latest-round		- Reads the last posted round in the mock."
	@echo "  get-round-data			- Reads round data for specified id,"
	@echo "  deposit				- Deposit collateral in the engine,"
	@echo "  mint					- Mints an amount of DSC."
	@echo "  deposit-and-mint		- Deposit collateral and mint DSC in one transaction."
	@echo "  redeem					- Redeem collateral from the engine."
	@echo "  burn					- Burn an amount of DSC."
	@echo "  burn-and-redeem		- Burns DSC and redeem collateral in one transaction."
	@echo "  liquidate				- Liquidates a position with broken health factor."
	@echo "  get-position-info		- Get information about a position."
	@echo "  get-price-feed			- Get the address of the Chainlink's ETH/USD price used in the engine."
	@echo "  get-dsc				- Get the address of the DSC token."
	@echo "  get-total-collateral	- Get the total collateral deposited in the engine."
	@echo "  get-dsc-supply			- Get DSC total supply."
	@echo "  setup-mock-users		- Creates mock positions for two Anvil accounts. One pos is safe while the other is close to liquidation."

# Clean forge build artifacts
clean:
	@echo "Cleaning project..."
	cd contracts/ && forge clean && rm -rf cache broadcast

reset: 
	@echo "Resetting dependencies..."
	rm -rf .gitmodules .git/modules/* contracts/lib
	touch .gitmodules
	git add .
	git commit -m "reset modules"

# Install all dependencies
install: install-app install-contracts

# Install app dependencies
install-app:
	@echo "Installing app dependencies..."
	cd app && npm i

# Install contracts dependencies
install-contracts:
	@echo "Installing contracts dependencies..."
	cd contracts && forge install && npm install

app:
	@echo "Starting app environment..."
	@trap 'kill 0' EXIT; \
	(cd app && npm run dev) & \
	wait

# Compile contracts
compile:
	@echo "Compiling contracts..."
	cd contracts && forge build

# Build all projects
build-app:
	@echo "Building all projects..."
	@(cd app && npm run build && npm run preview) & \
	wait

# Deploy contracts
deploy:
	@echo "Deploying smart contracts..."
	cd contracts && forge script scripts/DeploySystem.s.sol:DeploySystem --rpc-url $(RPC_URL) $(DEPLOYMENT_NETWORK_FLAGS) --broadcast -vv && npx tsx ./scripts/utils/syncContractArtifacts.ts --chain-id $(CHAIN_ID)

# Run tests
test-contracts:
	@echo "Running tests..."
	cd contracts && forge test

# Format code
format:
	@echo "Formatting all code..."
	npx prettier --write . --ignore-path .prettierignore

# Starts development blockchain
anvil:
	@echo "Starting Anvil chain..."
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 12

# Update ETH price in MockAggregatorV3. Arguments: NEW_PRICE. Usage `make update-price NEW_PRICE=250000000000`
update-price:
	@echo "Updating price..."
	cd contracts && forge script scripts/utils/AggregatorV3Utils.s.sol:UpdatePrice --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv

# Update round data in MockAggregatorV3. Arguments: NEW_PRICE. Usage `make update-round-data NEW_PRICE=250000000000`
update-round-data:
	@echo "Updating price..."
	cd contracts && forge script scripts/utils/AggregatorV3Utils.s.sol:UpdateRoundData --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv

# Reads the last posted price
get-latest-price:
	@echo "Reading price..."
	cd contracts && forge script scripts/utils/AggregatorV3Utils.s.sol:GetLatestPrice --rpc-url $(RPC_URL) -vv
	
# Reads the last posted round
get-latest-round:
	@echo "Reading last round..."
	cd contracts && forge script scripts/utils/AggregatorV3Utils.s.sol:GetLatestRoundData --rpc-url $(RPC_URL) -vv
	
# Reads round data for specified id. Arguments: ROUND_ID. Usage `make get-round-data ROUND_ID=0`
get-round-data:
	@echo "Reading round data..."
	cd contracts && forge script scripts/utils/AggregatorV3Utils.s.sol:GetRoundData --rpc-url $(RPC_URL) -vv
	
# Deposits collateral into the engine. Arguments: AMOUNT. Usage `make deposit AMOUNT=$(cast to-wei 1)`
deposit:
	@echo "Depositing collateral..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:Deposit --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Mints DSC. Arguments: AMOUNT. Usage `make mint AMOUNT=$(cast to-wei 1)`
mint:
	@echo "Minting DSC..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:Mint --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Deposit and mint DSC. Arguments: VALUE, AMOUNT. Usage `make deposit-and-mint VALUE=$(cast to-wei 1) AMOUNT=$(cast to-wei 1)`
deposit-and-mint:
	@echo "Depositing collateral and minting DSC..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:DepositAndMint --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Redeem collateral. Arguments: VALUE. Usage `make redeem VALUE=$(cast to-wei 1)`
redeem:
	@echo "Redeeming collateral..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:Redeem --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Burns DSC. Arguments: AMOUNT. Usage `make burn AMOUNT=$(cast to-wei 1)`
burn:
	@echo "Burning DSC..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:Burn --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Burns DSC and redeem collateral. Arguments: AMOUNT, VALUE. Usage `make burn-and-redeem AMOUNT=$(cast to-wei 1) VALUE=$(cast to-wei 1)`
burn-and-redeem:
	@echo "Burning DSC and redeeming collateral..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:BurnAndRedeem --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv
	
# Liquidate a position. Arguments: USER, DETB_TO_COVER. Usage `make liquidate USER=0x... DEBT_TO_COVER=$(cast to-wei 1)`
liquidate:
	@echo "liquidating position..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:Liquidate --rpc-url $(RPC_URL) $(TRANSACTION_NETWORK_FLAGS) --broadcast -vv

# Get information about a position. Arguments: USER. Usage `make get-position-info USER=0x...` 
get-position-info:
	@echo "Getting position information..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:GetPositionInfo --rpc-url $(RPC_URL) -vv

# Get the address of the Chainlink's ETH/USD price feed. Arguments: none. Usage `make get-price-feed` 
get-price-feed:
	@echo "Getting price feed address..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:GetPriceFeed --rpc-url $(RPC_URL) -vv

# Get the address of the DSC token. Arguments: none. Usage `make get-dsc` 
get-dsc:
	@echo "Getting DSC address..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:GetDSC --rpc-url $(RPC_URL) -vv

# Get the total collateral deposited in the engine. Arguments: none. Usage `make get-total-collateral` 
get-total-collateral:
	@echo "Getting total collateral deposited..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:GetTotalDepositedCollateral --rpc-url $(RPC_URL) -vv

# Get the address of the DSC token. Arguments: none. Usage `make get-dsc-supply` 
get-dsc-supply:
	@echo "Getting DSC total supply..."
	cd contracts && forge script scripts/DSCEngineInteractions.s.sol:GetDSCSupply --rpc-url $(RPC_URL) -vv

# Creates mock positions for two Anvil users.
setup-mock-users:
	@echo "Creating mock positions.."
	AMOUNT=$$(cast to-wei 10) make deposit 
	AMOUNT=$$(cast to-wei 1250) make mint
	AMOUNT=$$(cast to-wei 1) PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d make deposit
	AMOUNT=$$(cast to-wei 1250) PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d make mint
