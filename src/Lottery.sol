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

    uint256 private sellPhaseEndTime;
    uint256 private claimPhaseEndTime;
    uint256 public end_time;

    uint16 public winningNumber;

    constructor() {
        end_time = block.timestamp + 1 days;
    }

    function buy(uint16 number) public payable {
        require(participants_number_list[msg.sender] == 0, "Already participated"); // 이미 참여한 번호가 있으면 예외 발생
        require(msg.value == ticket_price);
        require(block.timestamp < end_time, "Sell phase ended"); // 판매 기간이 끝나면 구매할 수 없음

        state_flag = true;

        participants_number_list[msg.sender] = number;    
        winner_amount += msg.value;
        participants[number].push(msg.sender);
    }

    function draw() public {
        require(block.timestamp >= end_time, "Cannot draw before end time");
        require(state_flag, "No participants");

        uint256 seed = uint256(blockhash(block.number - 1));
        winningNumber = uint16(uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % (2**10));

        uint16 current_num = participants_number_list[msg.sender];
        for(uint i=0; i<participants[current_num].length;i++){
            if(participants_number_list[participants[current_num][i]] == winningNumber){ // 참여한 사람들 중에서 당첨 번호와 일치하는 번호를 가진 사람을 구함
                winner_list[participants[current_num][i]] = winner_amount; // 당첨자 리스트에 추가
                winner_count++;
            }
        }
        state_flag = false;
        claimPhaseEndTime = block.timestamp + 24 hours;

    }

    function claim() public {
        require(!state_flag, "Draw not finished"); // 추첨이 끝나지 않았으면 수령할 수 없음
        require(block.timestamp < claimPhaseEndTime, "Claim phase ended"); // 마감 시간 이후에는 수령할 수 없음
        require(winner_count > 0, "No winners");

        uint amount = (winner_list[msg.sender] / winner_count);
        (bool _success, ) = payable(msg.sender).call{value: amount}("");
        require(_success, "Transfer failed");
        delete winner_list[msg.sender];
    }

    receive() payable external{}


}

