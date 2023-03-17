// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    uint256 public constant ticket_price = 0.1 ether;
    uint256 public start_time = block.timestamp;
    mapping(address => uint16) public participants_number_list;
    mapping(uint16 => uint) private participants_count;
    mapping(uint16 => address[]) private participants;
    mapping(address => uint) public winner_list;
    uint winner_count;

    bool state_flag;
    uint winner_amount;

    uint256 private claimPhaseEndTime;
    uint256 public end_time;

    uint16 public winningNumber;

    constructor() {
        end_time = block.timestamp + 1 days;
    }

    function buy(uint16 number) public payable {
        require(participants_number_list[msg.sender] == 0);
        require(msg.value == ticket_price);
        require(block.timestamp < end_time);

        state_flag = true;

        participants_number_list[msg.sender] = number;    
        winner_amount += msg.value;
        participants[number].push(msg.sender);
    }

    function draw() public {
        require(block.timestamp >= end_time);
        require(state_flag);

        uint256 seed = uint256(blockhash(block.number - 1));
        winningNumber = uint16(uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % (2**10));

        uint16 current_num = participants_number_list[msg.sender];
        for(uint i=0; i<participants[current_num].length;i++){
            if(participants_number_list[participants[current_num][i]] == winningNumber){ 
                winner_list[participants[current_num][i]] = winner_amount; 
                winner_count++;
            }
        }
        state_flag = false;
        claimPhaseEndTime = block.timestamp + 24 hours;

    }

    function claim() public {
        require(!state_flag); 
        require(block.timestamp < claimPhaseEndTime); 
        require(winner_count > 0);

        uint amount = (winner_list[msg.sender] / winner_count);
        (bool _success, ) = payable(msg.sender).call{value: amount}("");
        require(_success);
        delete winner_list[msg.sender];
    }

    receive() payable external{}


}
