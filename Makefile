include .env

build:
	forge clean && forge build

test: build
	forge test

simulate-deploy: build
	forge script script/Proxy-Pattern-With-OpenZeppelin/DeployMyERC20.s.sol:DeployMyERC20 --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

deploy: build
	forge script script/Proxy-Pattern-With-OpenZeppelin/DeployMyERC20.s.sol:DeployMyERC20 --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

upgrade: build
	forge script script/Proxy-Pattern-With-OpenZeppelin/UpgradeMyERC20.s.sol:UpgradeMyERC20Script --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)