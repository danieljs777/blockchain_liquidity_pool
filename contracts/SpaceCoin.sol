//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceLiquidPool.sol";

contract SpaceCoin is ERC20 {

  enum Phase
  {
      Seed,
      General,
      Open
  }

  bool private useTax = false;
  bool private active = true;
  Phase private phase = Phase.Seed;

  uint256 private TAX_PERC = 2;

  uint256 private constant MAX_SUPPLY = 500000;
  uint256 private constant GOAL_AMOUNT = 30000 ether;
  uint256 private constant MAX_PRIV_IND_CONTRIB = 1500 ether;
  uint256 private constant MAX_PRIV_TOTAL_CONTRIB = 15000 ether;
  uint256 private constant MAX_GEN_IND_CONTRIB = 1000 ether;
  uint256 public constant EXCHANGE_RATE = 5;

  address public immutable PROJECT_ADDRESS;
  address private immutable OWNER_ADDRESS;
  address private immutable TREASURY_ACC;
  SpaceLiquidPool private LIQUID_POOL;

  mapping(address => uint256) private investments;

  address[] private investors;
  mapping(address => bool) private whitelisted;

  address internal spaceRouter;

  function setRouter(address _spaceRouter) public onlyOwner {
    require(address(spaceRouter) == address(0x0), "WRITE_ONCE");
    spaceRouter = _spaceRouter;
  }

  function setTax(bool _active) public onlyOwner {
    useTax = _active;
  }

  function setActive(bool _active) public onlyOwner {
    active = _active;
  }

  constructor(address _treasuryAddr) ERC20("SpaceCoin", "SPC") {

    PROJECT_ADDRESS = address(this);
    OWNER_ADDRESS = msg.sender;
    TREASURY_ACC  = _treasuryAddr;

    _mint(_treasuryAddr, MAX_SUPPLY * (10 ** decimals()));

    whitelisted[msg.sender] = true;

  }

  function setLiquidityPool(SpaceLiquidPool _liquidPool) public onlyOwner
  {
    require(address(LIQUID_POOL) == address(0x0), "WRITE_ONCE");
    LIQUID_POOL = _liquidPool;
  }

  modifier onlyOwner() {
    require(msg.sender == OWNER_ADDRESS, "Only owners can call this functions");
    _;
  }

  function stepPhase() public onlyOwner
  {
    if(phase == Phase.Seed)
    {
        phase = Phase.General;
    }
    else if(phase == Phase.General)
    {
        phase = Phase.Open;
    }
  }

  function addWhitelist(address newInvestor) public onlyOwner
  {
      whitelisted[newInvestor] = true;
  }

  function deposit() external payable
  {
    uint256 _amount = msg.value;

    require(active == true, "ICO is not active");
    require(address(this).balance < GOAL_AMOUNT, "Limit raised");

    if(phase == Phase.Seed)
    {
      require(whitelisted[msg.sender] != false, "Investor is not in whitelist!");
      require(_amount <= MAX_PRIV_IND_CONTRIB, "Above Individual Limit in Private Phase");
      require(address(this).balance <= MAX_PRIV_TOTAL_CONTRIB, "Above Private Contribution");
    }

    if(phase == Phase.General)
    {
      require(msg.value <= MAX_GEN_IND_CONTRIB, "Above Individual Limit in Open Phase");
    }

    investments[msg.sender] += _amount;
    investors.push(msg.sender);

    if(phase == Phase.Open) {
      redeem();
    }

  }

  function redeem() public returns(bool) {

    require(phase == Phase.Open, "ICO is not opened");

    uint256 amount = investments[msg.sender] * EXCHANGE_RATE;

    investments[msg.sender] = 0;

    _transfer(TREASURY_ACC, msg.sender, amount);

    return true;

  }    

  function _transfer(address sender, address _recipient, uint256 _amount) internal override {

    if(useTax) {
      uint256 taxFee = (_amount * TAX_PERC) / 100;

      _amount -= taxFee;

      super._transfer(sender, TREASURY_ACC, taxFee);
    }

    super._transfer(sender, _recipient, _amount);

  }      

  function setAllowance(address _owner, address _spender, uint256 _amount) public returns (bool) {

    require(msg.sender == spaceRouter, "Only routers can call this functions");

    _approve(_owner, _spender, allowance(msg.sender, address(this)) + _amount);
    return true;

  }

  function sendTreasury() public onlyOwner {

    super._transfer(PROJECT_ADDRESS, address(TREASURY_ACC), balanceOf(address(this)));

  }

  function withdraw() external onlyOwner{

    require(phase == Phase.Open, "ICO is not opened");

    uint256 coins = address(this).balance * EXCHANGE_RATE;   

    super._transfer(address(TREASURY_ACC), address(LIQUID_POOL), coins);

    LIQUID_POOL.deposit{value: (address(this).balance)}(msg.sender, coins);

  }


}
