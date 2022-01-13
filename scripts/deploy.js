async function main() {
  const [owner] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", owner.address);

  console.log("Account balance:", (await owner.getBalance()).toString());

  const SpaceLiquidPool = await ethers.getContractFactory("SpaceLiquidPool");
  spaceLiquidPool = await SpaceLiquidPool.connect(owner).deploy();
  await spaceLiquidPool.deployed();

  console.log("LP deployed!");

  const SpaceCoin = await ethers.getContractFactory("SpaceCoin");
  spaceCoin = await SpaceCoin.connect(owner).deploy("0xb27f27bfe5904e7a6dCc3015eCdd37A878784b6c");
  await spaceCoin.deployed();

  await spaceCoin.setLiquidityPool(spaceLiquidPool.address);
  await spaceCoin.stepPhase();
  await spaceCoin.stepPhase();

  console.log("SpaceCoin deployed!");

  const SpaceRouter = await ethers.getContractFactory("SpaceRouter");
  spaceRouter = await SpaceRouter.connect(owner).deploy(spaceLiquidPool.address, spaceCoin.address);
  await spaceRouter.deployed();

  console.log("Router deployed!");

  console.log("Setting integrations to spaceLiquidPool");
  await spaceLiquidPool.setSpaceCoin(spaceCoin.address);

  await spaceCoin.setRouter(spaceRouter.address);

  console.log("SpaceCoin address:", spaceCoin.address);
  console.log("spaceLiquidPool address:", spaceLiquidPool.address);
  console.log("Router address:", spaceRouter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});