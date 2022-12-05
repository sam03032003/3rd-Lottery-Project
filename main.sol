// SPDX-License-Identfier:GPL-MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract ChainLinkLottery is VRFConsumerBase
{
    address public manager;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;

    
    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;


    constructor() VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
    )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18;    // 0.1 LINK


        manager = msg.sender;
        lotteryId = 1;
    }


    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
        selectWinner();
    }


    function getWinnerOfLottery(uint lottery) public view returns(address payable)
    {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns(uint)
    {
        return manager.balance;
    }

    function getPlayers() public view returns(address payable[] memory)
    {
        return players;
    }

    function enter() public payable
    {
        require(msg.value > 0.01 ether);

        players.push(payable(msg.sender));
    }

    function pickWinner() public onlyManager {
        getRandomNumber();
    }

    function selectWinner() public onlyManager
    {
        uint index = randomResult % players.length;
        players[index].transfer(manager.balance);

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;

        players = new address payable[](0);
    }

    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }
}