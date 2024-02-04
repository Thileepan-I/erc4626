const abi = require ("../out/VaultV2.sol/VaultV2.json");
const { ethers } = require("ethers");
require('dotenv').config();
const fs = require('fs');
const path = require('path');

const jsonFilePath = '../broadcast/DeployVaultV2.s.sol/80001/run-latest.json';
const absoluteFilePath = path.resolve(__dirname, jsonFilePath);

// Read the JSON file
const jsonData = fs.readFileSync(absoluteFilePath);
const data = JSON.parse(jsonData);

// Access the `transactions` array inside the root object
const transactions = data.transactions;

const getERC1967ProxyAddress = (transactions) => {
  const erc1967ProxyTransaction = transactions.find(transaction => transaction.contractName === "ERC1967Proxy");
  return erc1967ProxyTransaction ? erc1967ProxyTransaction.contractAddress : 'Not Found';
};

// RPC URL and provider initialization
const provider = new ethers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/Z63eRknGRKayFksi5zbqwCj_pr9baRm8");

// Wallet initialization
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Contract addresses and ABIs
const usdcAddress = "0xDB3cB4f2688daAB3BFf59C24cC42D4B6285828e9";
const faucetAddress = "0x1Cea3a83BA17692cEa8DB37D72446f014480F3bE";
const proxyAddress = getERC1967ProxyAddress(transactions);
// console.log(proxyAddress);
const PROXY_ABI = abi.abi;
// console.log(PROXY_ABI);
const FAUCET_ABI = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "token",
          "type": "address"
        }
      ],
      "name": "drip",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

const USDC_ABI = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]
  

// Initialize contract instances
const proxyContract = new ethers.Contract(proxyAddress, PROXY_ABI, wallet);
const faucetContract = new ethers.Contract(faucetAddress, FAUCET_ABI, wallet);
const usdcContract = new ethers.Contract(usdcAddress,USDC_ABI,wallet)

async function main() {
    // Check balance of asset in the user account
    let balanceOfAsset = await proxyContract.balanceOfAsset(wallet.address);
    let formattedBalance = await ethers.formatUnits(balanceOfAsset, 6);
    console.log(`Balance of user ${wallet.address} : ${formattedBalance} USDC`);

    // console.log(wallet.address);

    // If balance is less than 1e9, call drip function
    if(balanceOfAsset<1e8) {
        const dripTx = await faucetContract.drip(usdcAddress);
        await dripTx.wait();
        console.log(`Fetched USDC from Compound(${faucetAddress}) faucet . New balance: ${formattedBalance} USDC`);
    }

    // Approve USDC spending
    const approveAmount = 1e9; // 1000 USDC
    const formattedAmount = ethers.formatUnits(approveAmount,6);
    const approveTx = await usdcContract.approve(proxyAddress, approveAmount);
    await approveTx.wait();
    console.log(`Approved Vault(${proxyAddress}) to spend ${ethers.formatUnits(approveAmount,6)} USDC`);

    // Check allowanceAsset (assuming this function exists in your proxy contract)
    const allowance = await proxyContract.allowanceAsset(wallet.address, proxyAddress);
    console.log(`Allowance of ${formattedAmount} USDC set to Vault`);

    // Deposit assets into the proxy contract (assuming deposit function signature)
    const depositTx = await proxyContract.deposit(approveAmount,wallet.address);
    await depositTx.wait();
    console.log(`Deposited ${formattedAmount} USDC to Proxy`);

    // Supply to Compound through proxy (assuming function signature)
    const supplyTx = await proxyContract.supplyToCompound(approveAmount);
    await supplyTx.wait();
    console.log(`Supplied ${formattedAmount} USDC to Compound from Vault`);

    // Check whether cUSDC got minted after supplying
    let initialCUSDCBalance = await proxyContract.getMyCUSDCBalance();
    console.log(`Initial cUSDC(bigint) Balance: ${initialCUSDCBalance}`);

    // Wait 30 seconds to let interest generate
    console.log("Waiting for 30 seconds to check interest...")
    await new Promise(resolve => setTimeout(resolve, 30000));

    let newCUSDCBalance = await proxyContract.getMyCUSDCBalance();
    let forma
    console.log(`New cUSDC(uint) Balance: ${newCUSDCBalance}`);

    if(newCUSDCBalance > initialCUSDCBalance) {
        console.log(`Yield farming is working`);
    }

    // Withdraw from Compound
    // Placeholder for the amount to withdraw. Ensure you have the correct value here
    const withdrawTx = await proxyContract.withdrawFromCompound(approveAmount);
    await withdrawTx.wait();
    console.log(`Withdrawn ${formattedAmount} USDC from Compound to Vault`);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});