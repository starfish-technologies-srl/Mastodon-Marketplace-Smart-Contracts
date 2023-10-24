const ethers = require("ethers");

const provider = new ethers.providers.JsonRpcProvider("https://polygon-mainnet.infura.io/v3/585791a8c8d547a7a2cdb6319e1ec67b");
const wallet = new ethers.Wallet("2e00224c93030ff5828120645099b9ac36b26afa2bb7d94c3c71ae5cacb2baa6", provider);
const contractAddress = "0x4F3ce26D9749C0f36012C9AbB41BF9938476c462";
const inputData = "burnBatch(uint256)";

const transaction = {
  from: wallet.address,
  to: contractAddress,
  data: inputData,
};

async function generateAccessList() {
  try {
    const accessList = await provider.send("eth_createAccessList", [
      transaction,
    ]);
    console.log("Access List:", accessList);
  } catch (error) {
    console.error("Error generating access list:", error);
  }
}

generateAccessList();