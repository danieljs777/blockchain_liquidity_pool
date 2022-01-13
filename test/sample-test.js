const { expect } = require("chai");
const { ethers } = require("hardhat");
const SpaceLiquidPoolJSON = require("../artifacts/contracts/SpaceLiquidPool.sol/SpaceLiquidPool.json");
const SpaceRouterJSON = require("../artifacts/contracts/SpaceRouter.sol/SpaceRouter.json");
const SpaceCoinJSON = require("../artifacts/contracts/SpaceCoin.sol/SpaceCoin.json");

describe("SpaceContract", function () {
  
  let spaceCoin;
  let LpToken, lpToken;
  let SpaceLiquidPool, spaceLiquidPool;
  let owner, investor1, investor2, investor3;

  // it("Should deploy an ICO contract", async function () {
  //     expect(spaceContract.address).to.be.ok;
  // });

  // beforeEach(async () => {

  it("Basic flow", async () => {    
    [owner, investor1, investor2, investor3] = await ethers.getSigners();

    const SpaceLiquidPool = await ethers.getContractFactory("SpaceLiquidPool");
    spaceLiquidPool = await SpaceLiquidPool.connect(owner).deploy();
    await spaceLiquidPool.deployed();

    // const LpToken = await ethers.getContractFactory("LpToken");
    // lpToken = await LpToken.connect(owner).deploy(spaceLiquidPool.address);
    // await lpToken.deployed();

    const SpaceCoin = await ethers.getContractFactory("SpaceCoin");
    spaceCoin = await SpaceCoin.connect(owner).deploy("0xb27f27bfe5904e7a6dCc3015eCdd37A878784b6c");
    await spaceCoin.deployed();

    await spaceCoin.connect(owner).setLiquidityPool(spaceLiquidPool.address);

    // await spaceLiquidPool.connect(owner).setLtpToken(lpToken.address);
    await spaceLiquidPool.connect(owner).setSpaceCoin(spaceCoin.address);

    const Router = await ethers.getContractFactory("SpaceRouter");
    spaceRouter = await Router.connect(owner).deploy(spaceLiquidPool.address, spaceCoin.address);
    await spaceRouter.deployed();

    await spaceCoin.setRouter(spaceRouter.address);

//     console.log("Owner : " + owner.address);
//     console.log("investor1 : " + investor1.address);
//     console.log("investor2 : " + investor2.address);

    // // console.log(ethers.utils.parseEther('3'));

    await spaceCoin.connect(owner).addWhitelist( investor1.address );
    await spaceCoin.connect(owner).addWhitelist( investor2.address );
    await spaceCoin.connect(owner).addWhitelist( investor3.address );

    await spaceCoin.connect(owner).deposit( { value: ethers.utils.parseEther('1500') } );
    await spaceCoin.connect(investor1).deposit({ value: ethers.utils.parseEther('1500') });

    // console.log("TOKENS", await spaceCoin.connect(owner).getBalance());

    await spaceCoin.connect(owner).stepPhase();
  // });

    await spaceCoin.connect(owner).stepPhase();

    await spaceCoin.connect(owner).deposit( { value: ethers.utils.parseEther('1500') } );
  // it("Phases ahead contributions", async () => {
    await spaceCoin.connect(investor2).deposit({ value: ethers.utils.parseEther('1000') });

    await spaceCoin.connect(investor3).deposit({ value: ethers.utils.parseEther('500') });
    await spaceCoin.connect(investor3).deposit({ value: ethers.utils.parseEther('5000') });


  });

  it("Withdrawing", async () => {

    // console.log(await spaceCoin.balanceOf(spaceLiquidPool.address));
    // console.log(await spaceLiquidPool.connect(owner).getReserves());

    await spaceCoin.connect(owner).withdraw();

    // console.log("QUOTATION", currentSpcToEthPrice);

    // console.log(await spaceLiquidPool.connect(owner).getReserves());

    // console.log(await spaceCoin.balanceOf(spaceLiquidPool.address));

    // console.log(await (spaceLiquidPool.connect(owner).getQuotationEther()));

  });

  it("Push Liquidity", async () => {

    await spaceRouter.connect(owner).pushLiquidity(ethers.utils.parseEther('2500'), { value: ethers.utils.parseEther('500') });
    currentSpcToEthPrice = await (spaceLiquidPool.connect(owner).getQuotationEther());

  });

  it("Swap", async () => {

    await spaceRouter.connect(investor3).swap(ethers.utils.parseEther('1'), 5, { value: 0 });

    await spaceRouter.connect(investor2).swap(0, 10, { value: ethers.utils.parseEther('2000') });

  });

  it("Only owner can pause contract", async () => {

    await expect(
      spaceCoin.connect(investor2).setActive(false)
    ).to.be.revertedWith("Only owners can call this functions");

  });


});
