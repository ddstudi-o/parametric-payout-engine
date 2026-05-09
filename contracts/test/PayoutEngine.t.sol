// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../src/PayoutEngine.sol";

// Minimal Foundry Cheatcode Interface (no external libs needed)
interface Vm {
    function prank(address) external;
    function deal(address, uint256) external;
    function expectRevert(bytes calldata) external;
}

contract PayoutEngineTest {
    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    PayoutEngine public engine;
    address public oracle = address(0x123);
    address public user = address(0x456);

    function setUp() public {
        engine = new PayoutEngine(oracle);
        vm.deal(address(engine), 10 ether);
    }

    function test_OracleCanExecutePayout() public {
        bytes32 triggerId = keccak256("demo-aws-outage");
        uint256 amount = 1 ether;
        uint256 balanceBefore = user.balance;

        vm.prank(oracle);
        engine.executePayout(triggerId, user, amount);

        assert(user.balance == balanceBefore + amount);
        assert(engine.processedTriggers(triggerId));
    }

    function test_Revert_IfNotOracle() public {
        bytes32 triggerId = keccak256("fake-trigger");
        vm.expectRevert("Not oracle");
        vm.prank(user);
        engine.executePayout(triggerId, user, 1 ether);
    }

    function test_Revert_IfDoubleSpend() public {
        bytes32 triggerId = keccak256("double-spend");
        
        vm.prank(oracle);
        engine.executePayout(triggerId, user, 1 ether);

        vm.expectRevert("Already processed");
        vm.prank(oracle);
        engine.executePayout(triggerId, user, 1 ether);
    }
}