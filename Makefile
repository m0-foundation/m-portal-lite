# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Deploy Hub

deploy-hub: 
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) forge script script/deploy/DeployHub.s.sol:DeployHub --rpc-url $(RPC_URL)  --skip test --slow --non-interactive -v

deploy-hub-sepolia: RPC_URL=$(SEPOLIA_RPC)
deploy-hub-sepolia: deploy-hub

deploy-hub-eth: RPC_URL=$(ETHEREUM_RPC)
deploy-hub-eth: deploy-hub

# Deploy Spoke

