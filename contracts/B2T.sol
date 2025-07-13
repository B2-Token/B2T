// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title B2 Token (B2T)
/// @notice A deflationary utility token on BNB Smart Chain with fixed supply, tax, and burn mechanics
contract B2T {
    string public name = "B2 Token";
    string public symbol = "B2T";
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

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Initializes contract and mints total supply to deployer
    /// @param _taxWallet Address where tax fees are collected
    constructor(address _taxWallet) {
        owner = msg.sender;
        taxWallet = _taxWallet;
        balanceOf[msg.sender] = totalSupply;
    }

    /// @notice Transfer tokens to another address applying tax and burn
    /// @param to Recipient address
    /// @param value Amount to transfer
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

    /// @notice Approve spender to transfer tokens on your behalf
    /// @param spender Address authorized to spend
    /// @param value Amount approved
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @notice Transfer tokens from one address to another using allowance
    /// @param from Sender address
    /// @param to Recipient address
    /// @param value Amount to transfer
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

    /// @notice (Optional) Update tax wallet address (only owner)
    /// @param _newTaxWallet New tax wallet address
    function updateTaxWallet(address _newTaxWallet) external onlyOwner {
        taxWallet = _newTaxWallet;
    }

    /// @notice (Optional) Update tax and burn percentages (only owner)
    /// @param _taxPercent New tax percentage
    /// @param _burnPercent New burn percentage
    function updatePercents(uint256 _taxPercent, uint256 _burnPercent) external onlyOwner {
        taxPercent = _taxPercent;
        burnPercent = _burnPercent;
    }
}
