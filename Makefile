# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Deploy Hub

deploy-hub: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeployHub.s.sol:DeployHub --rpc-url $(RPC_URL) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --skip test --broadcast \
	--slow --non-interactive -v --verify

deploy-hub-sepolia: RPC_URL=$(SEPOLIA_RPC)
deploy-hub-sepolia: deploy-hub

deploy-hub-eth: RPC_URL=$(ETHEREUM_RPC)
deploy-hub-eth: deploy-hub

# Deploy Spoke

deploy-spoke: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySpoke.s.sol:DeploySpoke --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v --verify \
    --verifier sourcify --verifier-url https://sourcify.parsec.finance/verify

deploy-spoke-hyper-evm-testnet: RPC_URL=$(HYPEREVM_TESTNET_RPC)
deploy-spoke-hyper-evm-testnet: deploy-spoke

# Configure 

configure: PEERS ?= []
configure:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/configure/Configure.s.sol:Configure \
	--sig "run(uint256[])" $(PEERS) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive

configure-sepolia: RPC_URL=$(SEPOLIA_RPC)
configure-sepolia: configure

