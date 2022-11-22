const hre = require("hardhat");
require("@nomiclabs/hardhat-web3");
require('@openzeppelin/hardhat-upgrades');

const OLDPROXY = '';
async function main() {
  const chainId = hre.network.config.chainId;

  const vrfCoordinator = {
    5: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
  };

  const sKeyHash = {
    5: "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
  }

  const subscriptionId = {
    5: "6766",
  }

  const [owner] = await ethers.getSigners();

  const PoolContract = await ethers.getContractFactory('Pool');
  const instance = await hre.upgrades.deployProxy(PoolContract, [owner.address, subscriptionId[chainId], vrfCoordinator[chainId], sKeyHash[chainId]], { initializer: 'initialize' });

  await instance.deployed();
  console.log("PoolContract deployed to:", instance.address)
 
  
  // Update impllementation for proxy
  // const PoolContract = await ethers.getContractFactory('Pool');
  // await upgrades.upgradeProxy(OLDPROXY, PoolContract);
  
  
  // Verify implementation contract
  // await hre.run("verify:verify", {
  //   address: "0xdbdc9a68fa1fb66ac14f82afe0b74f23b249672b",
  //   constructorArguments: [],
  // });
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
