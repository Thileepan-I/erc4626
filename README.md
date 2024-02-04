# ERC 4636 Vault liquidity staking with yield farming strategy in Compound V3

This is a UUPS upgradeable vault where users can deposit asset(used USDC from Compound). That deposited amount can be used by `SPENDER_ROLE` to provide it compound yield farming. Users receive representation token when deposit in 1:1 share and that needs to be burnt to withdraw assets from vault. During emergency withdrawal situation, `minimumReserve` amount is set to prevent emptying liquidity. Roles are implemented such that only `DEFAULT_ADMIN` role can add or revoke other roles and `UPGRADER_ROLE` upgrades the vault contract. 

Here Polygon mumbai testnet is used. Deployed contracts, provided USDC to compound and checked yield farm in testnet.

### Deployed Contacts
1.Vault V1 - [0xfd5203e97dc548B3951F71d08B04Bf272dA70F60](https://mumbai.polygonscan.com/address/0xfd5203e97dc548B3951F71d08B04Bf272dA70F60)
2. Vault V2 - [0xec2ad735C500Dc7AaF77E31051b5c63360413E81](https://mumbai.polygonscan.com/address/0xec2ad735C500Dc7AaF77E31051b5c63360413E81)
3. Proxy contract - [0x39D3042ee6535AF0b11f0B62Af4e1Bc723Dc297A](https://mumbai.polygonscan.com/address/0x39D3042ee6535AF0b11f0B62Af4e1Bc723Dc297A)

## Steps to clone the repo

### 1. Clone the repo. Run `forge install` and `npm install` to install all the packages.
### 2. Run `forge test` to test working of vault, access control and reserve logic.
### 3. Setup .env file. Run `source .env` to fetch .env to commands.
### 4. Deploy Vault V1 with `make deployv1` which deploys VaultV1.sol and ERC1967Proxy.sol.
### 5. Deploy Vault V2 with `make deployv2` which deploys VaultV2.sol and sets this address in Proxy.
### 6. Run `node script/YieldFarming.js` to send transactions in mumbai testnet and test the yield farming in Compound V3 testnet.