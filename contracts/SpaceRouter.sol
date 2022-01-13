//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SpaceCoin.sol";
import "./SpaceLiquidPool.sol";

contract SpaceRouter {

    SpaceLiquidPool private immutable LIQUID_POOL;
    SpaceCoin private immutable SPACE_COIN;  

    constructor(SpaceLiquidPool _liquidityPool, SpaceCoin _spaceCoin) {
        LIQUID_POOL = _liquidityPool;
        SPACE_COIN = _spaceCoin;
    }

    function pushLiquidity(uint256 _amount) external payable {

        require(SPACE_COIN.balanceOf(msg.sender) > 0, "You dont have tokens");

        bool success = SPACE_COIN.setAllowance(msg.sender, address(this), _amount);
        require(success);

        SPACE_COIN.transferFrom(msg.sender, address(LIQUID_POOL), _amount);
        LIQUID_POOL.deposit{value: msg.value}(_amount);
    }


    function pullLiquidity() external {

        LIQUID_POOL.withdraw();
    }

    function swap(uint256 _amount, uint8 _max_slippage) external payable {

        uint256 ethAmount = msg.value;
        uint256 spcAmount = _amount;

        require(calcSlippage(ethAmount, spcAmount) <= _max_slippage, "Max Slippage Overflowed");

        bool success = SPACE_COIN.setAllowance(msg.sender, address(this), _amount);
        require(success);

        SPACE_COIN.transferFrom(msg.sender, address(LIQUID_POOL), _amount);
        LIQUID_POOL.swap{value: msg.value}(msg.sender, _amount);        

    }

    function calcSlippage(uint256 ethAmount, uint256 spcAmount) public view returns (uint256) {

        (uint256 cEthAmount, uint256 cSpcAmount) = LIQUID_POOL.getReserves();

        require((cEthAmount > 0 && cSpcAmount > 0), "Not enough balance!");

        uint256 amountOut = LIQUID_POOL.getAmountOut(ethAmount, spcAmount);

        uint256 priceExpected;

        uint256 currentPrice = (cSpcAmount / cEthAmount) * 100;

        if(ethAmount == 0) {

            priceExpected = (spcAmount > amountOut ? spcAmount * 100 / amountOut : amountOut * 100 / spcAmount);


        } else {

            priceExpected = (ethAmount > amountOut ? ethAmount * 100 / amountOut : amountOut * 100 / ethAmount);

        }

        uint256 slippage = (priceExpected > currentPrice ? priceExpected - currentPrice : currentPrice - priceExpected);

        return (priceExpected > currentPrice ? currentPrice / ((slippage) * 100) : currentPrice * 100 / ((slippage - 1) * 100));

    }

}
