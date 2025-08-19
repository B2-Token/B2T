// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * B2 Token (B2T)
 *
 * Key properties:
 * - Fixed supply: 21,000,000 B2T (18 decimals), minted to deployer at construction.
 * - No tax (no tax wallet).
 * - Transfer burn in basis points (bps). Example: 100 = 1.00%. Capped by MAX_BURN_BPS.
 * - Fee exemptions for specific addresses (e.g., deployer, vault, founder, LP pair) to avoid burn on setup flows.
 * - finalize(): permanently locks parameter changes (burn bps + fee exemptions).
 * - Simple ownership (transfer/renounce).
 * - Rescue function for non-B2T tokens accidentally sent to the contract.
 */

interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract B2T {
    // --- ERC20 metadata ---
    string public name = "B2 Token";
    string public symbol = "B2T";
    uint8  public decimals = 18;

    // --- ERC20 totals ---
    uint256 public totalSupply;

    // --- Ownership / controls ---
    address public owner;
    bool    public finalized;

    // --- Burn configuration ---
    // burnBps: basis points (bps). 100 = 1.00%, 1 = 0.01%
    uint256 public burnBps = 100;                // default 1.00%
    uint256 public constant MAX_BURN_BPS = 100;  // max 1.00%

    // Addresses exempt from burn on transfers
    mapping(address => bool) public isFeeExempt;

    // --- ERC20 storage ---
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BurnBpsUpdated(uint256 oldBps, uint256 newBps);
    event FeeExemptUpdated(address indexed account, bool isExempt);
    event Finalized();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        // Mint full supply to deployer
        uint256 supply = 21_000_000 * (10 ** uint256(decimals));
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);

        // Deployer is exempt by default (to move initial allocations without burn)
        isFeeExempt[msg.sender] = true;
        emit FeeExemptUpdated(msg.sender, true);
    }

    // --- Ownership ---
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    // --- Parameter controls (only before finalize) ---
    function setBurnBps(uint256 _bps) external onlyOwner {
        require(!finalized, "Params locked");
        require(_bps <= MAX_BURN_BPS, "Burn too high");
        uint256 old = burnBps;
        burnBps = _bps;
        emit BurnBpsUpdated(old, _bps);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        require(!finalized, "Params locked");
        isFeeExempt[account] = exempt;
        emit FeeExemptUpdated(account, exempt);
    }

    /// Permanently lock parameter changes (burn bps + fee exemptions).
    /// After calling this, you may optionally renounce ownership to freeze everything, including rescue.
    function finalize() external onlyOwner {
        require(!finalized, "Already finalized");
        finalized = true;
        emit Finalized();
    }

    // --- ERC20 core ---
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transferWithBurn(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "Allowance exceeded");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - value;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }
        _transferWithBurn(from, to, value);
        return true;
    }

    // --- Internal transfer with optional burn ---
    function _transferWithBurn(address from, address to, uint256 value) internal {
        require(to != address(0), "Zero to");
        require(balanceOf[from] >= value, "Insufficient balance");

        // If burn is disabled or either side is exempt, do a plain transfer
        if (burnBps == 0 || isFeeExempt[from] || isFeeExempt[to]) {
            balanceOf[from] -= value;
            balanceOf[to]   += value;
            emit Transfer(from, to, value);
            return;
        }

        uint256 burnAmount = (value * burnBps) / 10_000; // bps to percentage
        uint256 sendAmount = value - burnAmount;

        // Debit total from sender
        balanceOf[from] -= value;

        // Burn portion
        if (burnAmount > 0) {
            totalSupply -= burnAmount;
            emit Transfer(from, address(0), burnAmount);
        }

        // Credit net to recipient
        balanceOf[to] += sendAmount;
        emit Transfer(from, to, sendAmount);
    }

    // --- Rescue non-native tokens (cannot rescue B2T itself) ---
    function rescueTokens(address token, uint256 amount, address to) external onlyOwner {
        require(token != address(this), "Cannot rescue B2T");
        require(to != address(0), "Zero to");
        IERC20Minimal(token).transfer(to, amount);
    }
}
