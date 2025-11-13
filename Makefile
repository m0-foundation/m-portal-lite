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
	--skip test --slow --non-interactive -v \
	--evm-version ${EVM_VERSION} \
	--skip test --broadcast --slow --non-interactive -v \
  --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

deploy-spoke-bsc: RPC_URL=$(BSC_RPC)
deploy-spoke-bsc: EVM_VERSION="cancun"
deploy-spoke-bsc: VERIFIER="etherscan"
deploy-spoke-bsc: VERIFIER_URL=$(BSC_VERIFIER_URL)
deploy-spoke-bsc: deploy-spoke

deploy-spoke-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC)
deploy-spoke-bsc-testnet: EVM_VERSION="cancun"
deploy-spoke-bsc-testnet: VERIFIER="etherscan"
deploy-spoke-bsc-testnet: VERIFIER_URL=$(BSC_TESTNET_VERIFIER_URL)
deploy-spoke-bsc-testnet: deploy-spoke

deploy-spoke-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
deploy-spoke-hyper-evm: EVM_VERSION="cancun"
deploy-spoke-hyper-evm: VERIFIER="blockscout"
deploy-spoke-hyper-evm: VERIFIER_URL=$(HYPEREVM_VERIFIER_URL)
deploy-spoke-hyper-evm: deploy-spoke

deploy-spoke-hyper-evm-testnet: RPC_URL=$(HYPEREVM_TESTNET_RPC)
deploy-spoke-hyper-evm-testnet: EVM_VERSION="cancun"
deploy-spoke-hyper-evm-testnet: VERIFIER="blockscout"
deploy-spoke-hyper-evm-testnet: VERIFIER_URL=$(HYPEREVM_VERIFIER_URL)
deploy-spoke-hyper-evm-testnet: deploy-spoke

deploy-spoke-plume: RPC_URL=$(PLUME_RPC)
deploy-spoke-plume: EVM_VERSION="cancun"
deploy-spoke-plume: VERIFIER="blockscout"
deploy-spoke-plume: VERIFIER_URL=$(PLUME_VERIFIER_URL)
deploy-spoke-plume: deploy-spoke

deploy-spoke-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
deploy-spoke-plume-testnet: EVM_VERSION="cancun"
deploy-spoke-plume-testnet: VERIFIER="blockscout"
deploy-spoke-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_VERIFIER_URL)
deploy-spoke-plume-testnet: deploy-spoke

deploy-spoke-linea: RPC_URL=$(LINEA_RPC)
deploy-spoke-linea: EVM_VERSION="london"
deploy-spoke-linea: VERIFIER="etherscan"
deploy-spoke-linea: VERIFIER_URL=$(LINEA_VERIFIER_URL)
deploy-spoke-linea: deploy-spoke

deploy-spoke-soneium-testnet: RPC_URL=$(SONEIUM_TESTNET_RPC)
deploy-spoke-soneium-testnet: EVM_VERSION="cancun"
deploy-spoke-soneium-testnet: VERIFIER="blockscout"
deploy-spoke-soneium-testnet: VERIFIER_URL=$(SONEIUM_TESTNET_VERIFIER_URL)
deploy-spoke-soneium-testnet: deploy-spoke

deploy-spoke-manta: RPC_URL=$(MANTRA_RPC)
deploy-spoke-manta: EVM_VERSION="cancun"
deploy-spoke-manta: VERIFIER="blockscout"
deploy-spoke-manta: VERIFIER_URL=$(MANTRA_VERIFIER_URL)
deploy-spoke-manta: deploy-spoke

deploy-spoke-wrapped_m:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySpokeWrappedM.s.sol:DeploySpokeWrappedM --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v \
  --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

deploy-spoke-wrapped_m-bsc: RPC_URL=$(BSC_RPC)
deploy-spoke-wrapped_m-bsc: VERIFIER="etherscan"
deploy-spoke-wrapped_m-bsc: VERIFIER_URL=$(BSC_VERIFIER_URL)
deploy-spoke-wrapped_m-bsc: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC)
deploy-spoke-wrapped_m-bsc-testnet: VERIFIER="etherscan"
deploy-spoke-wrapped_m-bsc-testnet: VERIFIER_URL=$(BSC_TESTNET_VERIFIER_URL)
deploy-spoke-wrapped_m-bsc-testnet: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-hyper-evm: RPC_URL=$(HYPEREVM_RPC)
deploy-spoke-wrapped_m-hyper-evm: VERIFIER="blockscout"
deploy-spoke-wrapped_m-hyper-evm: VERIFIER_URL=$(HYPEREVM_VERIFIER_URL)
deploy-spoke-wrapped_m-hyper-evm: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-plume: RPC_URL=$(PLUME_RPC)
deploy-spoke-wrapped_m-plume: VERIFIER="blockscout"
deploy-spoke-wrapped_m-plume: VERIFIER_URL=$(PLUME_VERIFIER_URL)
deploy-spoke-wrapped_m-plume: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
deploy-spoke-wrapped_m-plume-testnet: VERIFIER="blockscout"
deploy-spoke-wrapped_m-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_VERIFIER_URL)
deploy-spoke-wrapped_m-plume-testnet: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-soneium-testnet: RPC_URL=$(SONEIUM_TESTNET_RPC)
deploy-spoke-wrapped_m-soneium-testnet: VERIFIER="blockscout"
deploy-spoke-wrapped_m-soneium-testnet: VERIFIER_URL=$(SONEIUM_TESTNET_VERIFIER_URL)
deploy-spoke-wrapped_m-soneium-testnet: deploy-spoke-wrapped_m

deploy-spoke-wrapped_m-manta: RPC_URL=$(MANTRA_RPC)
deploy-spoke-wrapped_m-manta: VERIFIER="blockscout"
deploy-spoke-wrapped_m-manta: VERIFIER_URL=$(MANTRA_VERIFIER_URL)
deploy-spoke-wrapped_m-manta: deploy-spoke-wrapped_m

#
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

configure-mantra: RPC_URL=$(MANTRA_RPC)
configure-mantra: configure

configure-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
configure-plume-testnet: configure

configure-linea: RPC_URL=$(LINEA_RPC)
configure-linea: configure

configure-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC)
configure-bsc-testnet: configure

configure-bsc: RPC_URL=$(BSC_RPC)
configure-bsc: configure

propose-configure: PEERS ?= []
propose-configure:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/configure/ProposeConfigure.s.sol:ProposeConfigure \
	--sig "run(uint256[])" $(PEERS) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast --ffi

propose-configure-ethereum: RPC_URL=$(ETHEREUM_RPC)
propose-configure-ethereum: propose-configure

propose-transfer-pauser: NEW_PAUSER ?= 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1
propose-transfer-pauser:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/execute/ProposeTransferPauserRole.s.sol:ProposeTransferPauserRole \
	--sig "run(address)" $(NEW_PAUSER) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast --ffi

propose-transfer-pauser-ethereum: RPC_URL=$(ETHEREUM_RPC)
propose-transfer-pauser-ethereum: propose-transfer-pauser

propose-transfer-ownership: NEW_OWNER ?= 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468
propose-transfer-ownership: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/execute/ProposeTransferOwnership.s.sol:ProposeTransferOwnership \
	--sig "run(address)" $(NEW_OWNER) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast --ffi

propose-transfer-ownership-ethereum: RPC_URL=$(ETHEREUM_RPC)
propose-transfer-ownership-ethereum: propose-transfer-ownership

propose-renounce-timelock-admin: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/execute/ProposeRenounceTimelockAdmin.s.sol:ProposeRenounceTimelockAdmin \
	--sig "run()" \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast --ffi

propose-renounce-timelock-admin-ethereum: RPC_URL=$(ETHEREUM_RPC)
propose-renounce-timelock-admin-ethereum: propose-renounce-timelock-admin

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
upgrade-spoke-hyper-evm: VERIFIER="blockscout"
upgrade-spoke-hyper-evm: VERIFIER_URL=$(HYPEREVM_VERIFIER_URL)
upgrade-spoke-hyper-evm: upgrade-spoke

upgrade-spoke-plume-testnet: RPC_URL=$(PLUME_TESTNET_RPC)
upgrade-spoke-plume-testnet: VERIFIER="blockscout"
upgrade-spoke-plume-testnet: VERIFIER_URL=$(PLUME_TESTNET_VERIFIER_URL)
upgrade-spoke-plume-testnet: upgrade-spoke

propose-upgrade-hub: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/ProposeUpgradeHubPortal.s.sol:ProposeUpgradeHubPortal \
	--rpc-url $(RPC_URL) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	--slow --non-interactive -v --skip test --broadcast --verify --ffi

propose-upgrade-hub-ethereum: RPC_URL=$(ETHEREUM_RPC)
propose-upgrade-hub-ethereum: propose-upgrade-hub

propose-upgrade-spoke: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/ProposeUpgradeSpokePortal.s.sol:ProposeUpgradeSpokePortal \
	--rpc-url $(RPC_URL) \
	--sig "run(uint256)" $(PEER_CHAIN_ID) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --verifier $(VERIFIER) --verifier-url $(VERIFIER_URL) \
	--slow --non-interactive -v --skip test --broadcast --verify --ffi

propose-upgrade-spoke-linea: RPC_URL=$(LINEA_RPC)
propose-upgrade-spoke-linea: VERIFIER=etherscan
propose-upgrade-spoke-linea: VERIFIER_URL=$(LINEA_VERIFIER_URL)
propose-upgrade-spoke-linea: propose-upgrade-spoke

propose-upgrade-spoke-bsc: RPC_URL=$(BSC_RPC)
propose-upgrade-spoke-bsc: VERIFIER=etherscan
propose-upgrade-spoke-bsc: VERIFIER_URL=$(BSC_VERIFIER_URL)
propose-upgrade-spoke-bsc: propose-upgrade-spoke

# Upgrade M Token
upgrade-m-token:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/UpgradeSpokeMToken.s.sol:UpgradeSpokeMToken --rpc-url $(RPC_URL) \
	--skip test --broadcast --slow --non-interactive -v \
    --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

upgrade-m-token-local: RPC_URL=$(LOCALHOST_RPC)
upgrade-m-token-local: upgrade-m-token

upgrade-m-token-soneium-testnet: RPC_URL=$(SONEIUM_TESTNET_RPC)
upgrade-m-token-soneium-testnet: VERIFIER="blockscout"
upgrade-m-token-soneium-testnet: VERIFIER_URL=$(SONEIUM_TESTNET_VERIFIER_URL)
upgrade-m-token-soneium-testnet: upgrade-m-token

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

transfer-linea: RPC_URL=$(LINEA_RPC)
transfer-linea: transfer

transfer-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC)
transfer-bsc-testnet: transfer

transfer-bsc: RPC_URL=$(BSC_RPC)
transfer-bsc: transfer

transfer-mantra: RPC_URL=$(MANTRA_RPC)
transfer-mantra: transfer

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

transfer-m-like-token-linea: RPC_URL=$(LINEA_RPC)
transfer-m-like-token-linea: transfer-m-like-token

transfer-m-like-token-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC)
transfer-m-like-token-bsc-testnet: transfer-m-like-token

transfer-m-like-token-bsc: RPC_URL=$(BSC_RPC)
transfer-m-like-token-bsc: transfer-m-like-token

transfer-m-like-token-mantra: RPC_URL=$(MANTRA_RPC)
transfer-m-like-token-mantra: transfer-m-like-token
