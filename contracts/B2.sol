// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/access/Ownable.sol";

contract B2 is ERC20, Ownable {
    uint256 public taxPercent = 4;
    uint256 public burnPercent = 1;
    address public taxWallet;

    constructor(address _taxWallet) ERC20("B2", "B2") Ownable(msg.sender) {
        _mint(msg.sender, 21_000_000 * 10 ** decimals());
        taxWallet = _taxWallet;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address sender = _msgSender();
        uint256 taxAmount = (amount * taxPercent) / 100;
        uint256 burnAmount = (amount * burnPercent) / 100;
        uint256 finalAmount = amount - taxAmount - burnAmount;

        _transfer(sender, taxWallet, taxAmount);
        _burn(sender, burnAmount);
        _transfer(sender, recipient, finalAmount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = (amount * taxPercent) / 100;
        uint256 burnAmount = (amount * burnPercent) / 100;
        uint256 finalAmount = amount - taxAmount - burnAmount;

        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);

        _transfer(sender, taxWallet, taxAmount);
        _burn(sender, burnAmount);
        _transfer(sender, recipient, finalAmount);
        return true;
    }
}