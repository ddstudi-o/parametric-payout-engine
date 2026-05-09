// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PayoutEngine
 * @dev Autonomous parametric payout engine. No external dependencies.
 */
contract PayoutEngine {
    address public owner;
    address public verifiedOracle;
    bool public paused;
    mapping(bytes32 => bool) public processedTriggers;

    event PayoutExecuted(bytes32 indexed triggerId, address indexed recipient, uint256 amount);
    event OracleUpdated(address indexed newOracle);
    event Paused();
    event Unpaused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == verifiedOracle, "Not oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(address _initialOracle) {
        owner = msg.sender;
        verifiedOracle = _initialOracle;
    }

    function executePayout(bytes32 triggerId, address recipient, uint256 amount) external onlyOracle whenNotPaused {
        require(!processedTriggers[triggerId], "Already processed");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Zero amount");

        processedTriggers[triggerId] = true;
        emit PayoutExecuted(triggerId, recipient, amount);

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function setOracle(address _newOracle) external onlyOwner {
        verifiedOracle = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    receive() external payable {}
}