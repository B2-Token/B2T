// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract B2 {
    string public name = "B2";
    string public symbol = "B2";
    uint8 public decimals = 18;
    uint256 public totalSupply = 21000000 * 10**uint256(decimals);

    address public owner;
    uint256 public taxPercent = 4;
    uint256 public burnPercent = 1;
    address public taxWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _taxWallet) {
        owner = msg.sender;
        taxWallet = _taxWallet;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 taxAmount = (value * taxPercent) / 100;
        uint256 burnAmount = (value * burnPercent) / 100;
        uint256 finalAmount = value - taxAmount - burnAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += finalAmount;
        balanceOf[taxWallet] += taxAmount;
        totalSupply -= burnAmount;

        emit Transfer(msg.sender, to, finalAmount);
        emit Transfer(msg.sender, taxWallet, taxAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        uint256 taxAmount = (value * taxPercent) / 100;
        uint256 burnAmount = (value * burnPercent) / 100;
        uint256 finalAmount = value - taxAmount - burnAmount;

        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        balanceOf[to] += finalAmount;
        balanceOf[taxWallet] += taxAmount;
        totalSupply -= burnAmount;

        emit Transfer(from, to, finalAmount);
        emit Transfer(from, taxWallet, taxAmount);
        emit Transfer(from, address(0), burnAmount);
        return true;
    }
}
