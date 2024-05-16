//SPDX-License-Identifier:MIT

pragma solidity =0.6.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/UniswapV2Library.sol";

import "hardhat/console.sol";


contract FlashLoan{

    using SafeERC20 for IERC20;

    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;


    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;


    uint256 private deadline = block.timestamp + 1 days;

    uint256 private constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;



    function checkResult(uint256 amountWeGot , uint256 amountWeHaveToRepay) pure private returns(bool){

        return amountWeGot > amountWeHaveToRepay;

    }

    function getBalanceOfTokens(address _tokenAddress) view external returns(uint256){

        return IERC20(_tokenAddress).balanceOf(address(this));

    }

    function placeTrade(address token1 , address token2 , uint256 amountIn) private returns(uint256){

        address liquidityPool = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token1 , token2);

        require(liquidityPool != address(0) , "Couldnt Find The Pool");

        address[] memory path = new address[](2);

        path[0] = token1;

        path[1] = token2;


        uint256 amountExpected = IUniswapV2Router01(PANCAKE_FACTORY).getAmountsOut(amountIn, path)[1];

        uint256 amountGot = IUniswapV2Router01(PANCAKE_ROUTER).swapExactTokensForTokens(amountIn, amountExpected, path, address(this) , deadline)[1];

        require(amountGot > 0 , "Transaction failed");

        return amountGot;

    }


    function initiateArbitrage(address _borrowingBUSD , uint256 _amountOfBorrowing) external{

        IERC20(BUSD).safeApprove(address(PANCAKE_ROUTER) , MAX_INT);
        IERC20(CROX).safeApprove(address(PANCAKE_ROUTER) , MAX_INT);
        IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER) , MAX_INT);


        address liquidityPool = IUniswapV2Factory(PANCAKE_FACTORY).getPair(_borrowingBUSD , WBNB);

        require(liquidityPool != address(0) , "Pool doesnt exist");


        address token0 = IUniswapV2Pair(liquidityPool).token0();

        address token1 = IUniswapV2Pair(liquidityPool).token1();


        uint256 amount0Out = _borrowingBUSD == token0 ? _amountOfBorrowing : 0;

        uint256 amount1Out = _borrowingBUSD == token1 ? _amountOfBorrowing : 0;


        bytes memory data = abi.encode(_borrowingBUSD , _amountOfBorrowing , msg.sender);


        IUniswapV2Pair(liquidityPool).swap(amount0Out, amount1Out, address(this), data);


    }

    function pancakeCall(uint256 amount0 , uint256 amount1 , address _sender , bytes calldata _data) external {

        address token0 = IUniswapV2Pair(msg.sender).token0();

        address token1 = IUniswapV2Pair(msg.sender).token1();


        address liquidityPool = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);

        require(liquidityPool == msg.sender , "Pool doesnt match");

        require(_sender == address(this) , "Contract is not the sender");


        (address _borrowingBUSD , uint256 _amountOfBorrowing , address myAccount) = abi.decode(_data , (address , uint256 , address));


        //fee calculation


        uint256 fee = ((_amountOfBorrowing * 3)/997) + 1;

        uint256 repaymentAmount = _amountOfBorrowing + fee;

        uint256 loanAmount = amount0 > 0 ? amount0 : amount1;


        //triangular Arbitrage

        uint256 trade1Coin = placeTrade(BUSD , CROX , loanAmount);
        uint256 trade2Coin = placeTrade(CROX , CAKE , trade1Coin);
        uint256 trade3Coin = placeTrade(CAKE , BUSD , trade2Coin);


        bool result = checkResult(trade3Coin , repaymentAmount);

        require(result , "Arbitrage is not profitable");


        IERC20(BUSD).transfer(myAccount, trade3Coin - repaymentAmount);

        IERC20(_borrowingBUSD).transfer(liquidityPool, repaymentAmount);

    }

}


