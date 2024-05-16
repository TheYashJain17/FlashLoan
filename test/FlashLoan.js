const {assert , expect} = require('chai');

const {ethers} = require('hardhat');

const {fundContract} = require('../utils/utilities');

const {abi , bytecode} = require('../artifacts/contracts/interfaces/IERC20.sol/IERC20.json');

// const provider = new ethers.providers.JsonRpcProvider('https://bsc-dataseed1.binance.org/');

const provider = ethers.provider;

// const provider = waffle.provider;

describe("Testing Flash Loan Contract" , () => {


    let FLASHLOAN , BORROWED_AMOUNT , FUND_AMOUNT , initialFundinInHumanFormat , txArbitrage;

    const DECIMALS = 18;

    const BUSD_WHALE = '0xf977814e90da44bfa03b6295a0616a897441acec'
    const BUSD = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
    const CROX = '0x2c094F5A7D1146BB93850f629501eB749f6Ed491';
    const CAKE = '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82';

    const busdInstance = new ethers.Contract(

        BUSD,
        abi,
        provider

    );

    beforeEach(async() => {

        const WHALE_BALANCE = await provider.getBalance(BUSD_WHALE);

        console.log(`The Whale Balance is ${WHALE_BALANCE}`);
    
        expect(WHALE_BALANCE).not.equal(0);

        
        // console.log(provider)
        
    })

    // done();

    it("testing whale Balance" , async() => {
    
           
    
    })



})