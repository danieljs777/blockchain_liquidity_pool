import { ethers } from "ethers"
import { BigNumber} from "@ethersproject/bignumber";

const SpaceLiquidPoolJSON = require("../../artifacts/contracts/SpaceLiquidPool.sol/SpaceLiquidPool.json");
const SpaceRouterJSON = require("../../artifacts/contracts/SpaceRouter.sol/SpaceRouter.json");
const SpaceCoinJSON = require("../../artifacts/contracts/SpaceCoin.sol/SpaceCoin.json");

const provider = new ethers.providers.Web3Provider(window.ethereum)
const signer = provider.getSigner()

const spaceAddr = '0x773C69E26FB6292fDBfdED7eCf5b84A35c52238A'
const spaceCoin = new ethers.Contract(spaceAddr, SpaceCoinJSON.abi, provider);

const routerAddr = '0xfA5435Bc29eCCbBfFc91211E2033371De28243dA'
const router = new ethers.Contract(routerAddr, SpaceRouterJSON.abi, provider);

const liquidPoolAddr = '0x25c1cdAa7Ae568Dff409a9B83b00E003D4EbBF96'
const liquidPool = new ethers.Contract(liquidPoolAddr, SpaceLiquidPoolJSON.abi, provider);

async function connectToMetamask() {
  try {
    console.log("Signed in as", await signer.getAddress())
  }
  catch(err) {
    console.log("Not signed in")
    await provider.send("eth_requestAccounts", [])
  }
}

//
// ICO
//
ico_spc_buy.addEventListener('submit', async e => {
  e.preventDefault()
  const form = e.target
  const eth = ethers.utils.parseEther(form.eth.value)
  console.log("Buying", eth, "eth")

  await connectToMetamask()
  
  console.log(await spaceCoin.connect(signer).deposit({value: BigNumber.from(eth) }));

})


//
// LP
//
let currentSpcToEthPrice = 5

async function getSpcToEthPrice() {
  currentSpcToEthPrice = await (liquidPool.connect(signer).getQuotationEther());
}

provider.on("block", n => {
  console.log("New block", n)
  
  getSpcToEthPrice();
  
  console.log(currentSpcToEthPrice);
})

lp_deposit.eth.addEventListener('input', e => {
  lp_deposit.spc.value = +e.target.value * currentSpcToEthPrice
})

lp_deposit.spc.addEventListener('input', e => {
  lp_deposit.eth.value = +e.target.value / currentSpcToEthPrice
})

lp_deposit.addEventListener('submit', async e => {
  e.preventDefault()
  const form = e.target
  const eth = ethers.utils.parseEther(form.eth.value)
  const spc = ethers.utils.parseEther(form.spc.value)
  console.log("Depositing", eth, "eth and", spc, "spc")

  await connectToMetamask()
  // TODO: Call router contract deposit function
  await router.connect(signer).pushLiquidity(spc, { value: BigNumber.from(eth) });

})

lp_withdraw.addEventListener('submit', async e => {
  e.preventDefault()
  console.log("Withdrawing 100% of LP")

  await connectToMetamask()
  // TODO: Call router contract withdraw function
  await router.connect(signer).pullLiquidity();
})

//
// Swap
//
let swapIn = { type: 'eth', value: 0 }
let swapOut = { type: 'spc', value: 0 }
switcher.addEventListener('click', () => {
  [swapIn, swapOut] = [swapOut, swapIn]
  swap_in_label.innerText = swapIn.type.toUpperCase()
  swap.amount_in.value = swapIn.value
  updateSwapOutLabel()
})

swap.amount_in.addEventListener('input', updateSwapOutLabel)

function updateSwapOutLabel() {
  swapOut.value = swapIn.type === 'eth'
    ? +swap.amount_in.value * currentSpcToEthPrice
    : +swap.amount_in.value / currentSpcToEthPrice

  swap_out_label.innerText = `${swapOut.value} ${swapOut.type.toUpperCase()}`
}

swap.addEventListener('submit', async e => {
  e.preventDefault()
  const form = e.target
  const amountIn = ethers.utils.parseEther(form.amount_in.value)

  console.log("Swapping", amountIn, swapIn.type, "for", swapOut.type)

  await connectToMetamask()

  // TODO: Call router contract swap function
  if(swapIn.type == "eth")
    await router.connect(signer).swap(0, {value: BigNumber.from(amountIn)});
  else
    await router.connect(signer).swap(amountIn);


})
