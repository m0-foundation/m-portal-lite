# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

#
# Deploy Hub
#

deploy-hub: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeployHub.s.sol:DeployHub --rpc-url $(RPC_URL) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --skip test --broadcast \
	--slow --non-interactive -v --verify

deploy-hub-ethereum: RPC_URL=$(ETHEREUM_RPC)
deploy-hub-ethereum: deploy-hub

deploy-hub-sepolia: RPC_URL=$(SEPOLIA_RPC)
deploy-hub-sepolia: deploy-hub

#
# Deploy Spoke
#

deploy-spoke: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySpoke.s.sol:DeploySpoke --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v --verify \
    --verifier sourcify --verifier-url https://sourcify.parsec.finance/verify

deploy-spoke-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
deploy-spoke-hyper-evm: deploy-spoke

deploy-spoke-hyper-evm-testnet: RPC_URL=$(HYPEREVM_TESTNET_RPC)
deploy-spoke-hyper-evm-testnet: deploy-spoke

#
# Configure
#

configure: PEERS ?= []
configure:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/configure/Configure.s.sol:Configure \
	--sig "run(uint256[])" $(PEERS) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast

configure-ethereum: RPC_URL=$(ETHEREUM_RPC)
configure-ethereum: configure

configure-sepolia: RPC_URL=$(SEPOLIA_RPC)
configure-sepolia: configure

configure-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
configure-hyper-evm: configure

configure-hyper-evm-testnet: RPC_URL=$(HYPEREVM_TESTNET_RPC)
configure-hyper-evm-testnet: configure

#
# Execute
#

execute:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) forge script $(SCRIPT) --rpc-url $(RPC_URL) --skip test --slow -v --broadcast

#
# Send M Token Index
#

send-index: SCRIPT=script/execute/SendMTokenIndex.s.sol:SendMTokenIndex
send-index: execute

send-index-ethereum: RPC_URL=$(ETHEREUM_RPC)
send-index-ethereum: send-index

send-index-sepolia: RPC_URL=$(SEPOLIA_RPC)
send-index-sepolia: send-index

#
# Transfer
#

transfer: SCRIPT=script/execute/Transfer.s.sol:Transfer
transfer: execute

send-index-ethereum: RPC_URL=$(ETHEREUM_RPC)
send-index-ethereum: transfer

transfer-sepolia: RPC_URL=$(SEPOLIA_RPC)
transfer-sepolia: transfer





