-include	.env

deployv1:
	forge script script/DeployVaultV1.s.sol --broadcast --rpc-url $(RPC_URL)  --private-key $(PRIVATE_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify
deployv2:
	forge script script/DeployVaultV2.s.sol --broadcast --rpc-url $(RPC_URL)  --private-key $(PRIVATE_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify