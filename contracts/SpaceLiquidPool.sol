//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLiquidPool is ERC20 {

  address private immutable OWNER_ADDRESS;

  SpaceCoin private SPACE_COIN;  

  uint32 lastBlockTS;
  uint256 lastKonstant;

  uint256 public ethFunds;
  uint256 public spcFunds;

  constructor() ERC20("SpaceLiquidToken", "SLT") {

    OWNER_ADDRESS = msg.sender;

  }

  uint private locked = 0;

  modifier lock() {
      require(locked == 0, 'LP LOCKED');
      locked = 1;
      _;
      locked = 0;
  }  

  modifier onlyOwner() {
    require(msg.sender == OWNER_ADDRESS);
    _;
  }

  function setSpaceCoin(SpaceCoin _spaceCoin) external onlyOwner {
    require(address(SPACE_COIN) == address(0), "WRITE_ONCE");
    SPACE_COIN = _spaceCoin;

  }  

  function getReserves() external view returns (uint256, uint256) {

    return (ethFunds, spcFunds);
  }

  function applyFee(uint256 _amount) public pure returns (uint256) { 
    
    if(_amount > 0)
      return _amount - (_amount / 100);
    else
      return 0;
  }

  function deposit(address _account, uint256 _spcAmount) external payable lock {

    require(_spcAmount > 0, "Send an amount of SpaceCoin");
    require(_spcAmount / 5 == msg.value, "Send an even amount of SpaceCoin x Ether (1 ETH = 5 SPC)");

    uint256 ethAmount = msg.value;
    uint256 lptSupply = totalSupply();
    uint256 liquidity;

    if (lptSupply > 0) {

      liquidity = Math.min(
        (ethAmount * lptSupply) / ethFunds,
        (_spcAmount * lptSupply) / spcFunds
      );

    } else {

      liquidity = Babylonian.sqrt(ethAmount * _spcAmount);
    }

    _mint(_account, liquidity);

    _sync();

  }

  function getQuotationEther() external view returns (uint256) {

    return (ethFunds * 100) / spcFunds;
  }

  function withdraw(address _account) external lock {

    uint256 lptBalance = this.balanceOf(_account);
    require(lptBalance != 0, "No tokens");

    uint256 lptSupply = this.totalSupply();
    uint256 ethAmount = (ethFunds * lptBalance) / lptSupply;
    uint256 spcAmount = (spcFunds * lptBalance) / lptSupply;

    _burn(_account, lptBalance);

    bool spcSuccess = SPACE_COIN.transfer(_account, spcAmount);
    require(spcSuccess, "SpaceCoin transfer failed!");

    (bool ethSuccess, ) = _account.call{value: ethAmount}("");
    require(ethSuccess, "ETH transfer failed!");

    _sync();

  }

  function swap(address _account, uint256 _spcAmount) external payable lock {

    require(address(SPACE_COIN) != address(0), "Unset Space Coin");

    uint256 amount = getAmountOut(msg.value, _spcAmount);

    if (msg.value == 0) {

      (bool success, ) = _account.call{value: amount}("");

      require(success, "Transfer Failed");

    } else {

      SPACE_COIN.transfer(_account, amount);
    }

    _sync();

  }

  function getAmountOut(uint _ethAmount, uint _spcAmount) public view returns (uint) {

    require((_ethAmount > 0 || _spcAmount > 0) && (_ethAmount == 0 || _spcAmount == 0), "Exactly one value must be given");
    require(_ethAmount < ethFunds && _spcAmount < spcFunds, 'Insufficient liquidity');

    uint256 cpf = ethFunds * spcFunds;

    if (_ethAmount == 0) {

      return ethFunds - (cpf / (spcFunds + applyFee(_spcAmount)));

    } else {

      return spcFunds - (cpf / (ethFunds + applyFee(_ethAmount)));

    }


  }

  function _sync() private {

    require(address(SPACE_COIN) != address(0), "Unset Space Coin");

    uint32 blockTS = uint32(block.timestamp % 2**32);
    uint32 timeElapsed;

    unchecked {

      // Overflow desired
      timeElapsed = blockTS - lastBlockTS; 
    }

    if (timeElapsed > 0) {
      ethFunds = address(this).balance;
      spcFunds = SPACE_COIN.balanceOf(address(this));
      lastBlockTS = blockTS;
      lastKonstant = ethFunds * spcFunds;
    }

  }

}
