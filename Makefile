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
    --verifier blockscout --verifier-url $(VERIFIER_URL)
	
deploy-spoke-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
deploy-spoke-hyper-evm: VERIFIER_URL=$(HYPEREVM_EXPLORER)
deploy-spoke-hyper-evm: deploy-spoke

deploy-spoke-hyper-evm-testnet: RPC_URL=$(HYPEREVM_TESTNET_RPC)
deploy-spoke-hyper-evm-testnet: VERIFIER_URL=$(HYPEREVM_EXPLORER)
deploy-spoke-hyper-evm-testnet: deploy-spoke

deploy-spoke-plume: RPC_URL=$(PLUME_RPC)
deploy-spoke-plume: VERIFIER_URL=$(PLUME_EXPLORER)
deploy-spoke-plume: deploy-spoke

deploy-spoke-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
deploy-spoke-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_EXPLORER)
deploy-spoke-plume-testnet: deploy-spoke


deploy-spoke-wrapped_m:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySpokeWrappedM.s.sol:DeploySpokeWrappedM --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v --verify \
    --verifier blockscout --verifier-url $(VERIFIER_URL)

deploy-spoke-wrapped_m-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
deploy-spoke-wrapped_m-hyper-evm: VERIFIER_URL=$(HYPEREVM_EXPLORER)
deploy-spoke-wrapped_m-hyper-evm: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-plume: RPC_URL=$(PLUME_RPC)
deploy-spoke-wrapped_m-plume: VERIFIER_URL=$(PLUME_EXPLORER)
deploy-spoke-wrapped_m-plume: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
deploy-spoke-wrapped_m-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_EXPLORER)
deploy-spoke-wrapped_m-plume-testnet: deploy-spoke-wrapped_m

#
# Configure
#
# make configure-ethereum PEERS="[999]"

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

configure-plume: RPC_URL=$(PLUME_RPC)
configure-plume: configure

configure-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
configure-plume-testnet: configure

#
# Upgrade
#

# Upgrade Hub

upgrade-hub: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/UpgradeHubPortal.s.sol:UpgradeHubPortal --rpc-url $(RPC_URL) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --skip test --broadcast \
	--slow --non-interactive -v --verify

upgrade-hub-ethereum: RPC_URL=$(ETHEREUM_RPC)
upgrade-hub-ethereum: upgrade-hub

upgrade-hub-sepolia: RPC_URL=$(SEPOLIA_RPC)
upgrade-hub-sepolia: upgrade-hub

# Upgrade Spoke
upgrade-spoke: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/UpgradeSpokePortal.s.sol:UpgradeSpokePortal --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v --verify \
	--verifier blockscout --verifier-url $(VERIFIER_URL)
	
upgrade-spoke-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
upgrade-spoke-hyper-evm: VERIFIER_URL=$(HYPEREVM_EXPLORER)
upgrade-spoke-hyper-evm: upgrade-spoke

upgrade-spoke-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
upgrade-spoke-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_EXPLORER)
upgrade-spoke-plume-testnet: upgrade-spoke

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
# Send Earner Status
#

send-earner-status: SCRIPT=script/execute/SendEarnerStatus.s.sol:SendEarnerStatus
send-earner-status: execute

send-earner-status-ethereum: RPC_URL=$(ETHEREUM_RPC)
send-earner-status-ethereum: send-earner-status

send-earner-status-sepolia: RPC_URL=$(SEPOLIA_RPC)
send-earner-status-sepolia: send-earner-status

#
# Send Registrar Key
#

send-registrar-key: SCRIPT=script/execute/SendRegistrarKey.s.sol:SendRegistrarKey
send-registrar-key: execute

send-registrar-key-ethereum: RPC_URL=$(ETHEREUM_RPC)
send-registrar-key-ethereum: send-registrar-key

send-registrar-key-sepolia: RPC_URL=$(SEPOLIA_RPC)
send-registrar-key-sepolia: send-registrar-key

#
# Transfer
#

transfer: SCRIPT=script/execute/Transfer.s.sol:Transfer
transfer: execute

transfer-ethereum: RPC_URL=$(ETHEREUM_RPC)
transfer-ethereum: transfer

transfer-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
transfer-hyper-evm: transfer

transfer-sepolia: RPC_URL=$(SEPOLIA_RPC)
transfer-sepolia: transfer

transfer-plume: RPC_URL=$(PLUME_RPC)
transfer-plume: transfer

transfer-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
transfer-plume-testnet: transfer


#
# Transfer M like token
#

transfer-m-like-token: SCRIPT=script/execute/TransferMLikeToken.s.sol:TransferMLikeToken
transfer-m-like-token: execute

transfer-m-like-token-ethereum: RPC_URL=$(ETHEREUM_RPC)
transfer-m-like-token-ethereum: transfer-m-like-token

transfer-m-like-token-sepolia: RPC_URL=$(SEPOLIA_RPC)
transfer-m-like-token-sepolia: transfer-m-like-token

transfer-m-like-token-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
transfer-m-like-token-hyper-evm: transfer-m-like-token

transfer-m-like-token-plume: RPC_URL=$(PLUME_RPC)
transfer-m-like-token-plume: transfer-m-like-token

transfer-m-like-token-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
transfer-m-like-token-plume-testnet: transfer-m-like-token




