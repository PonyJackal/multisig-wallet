// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract MultiSigWalletTest is PRBTest, StdCheats {
    MultiSigWallet internal multiSigWallet;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal carol;

    function setUp() public virtual {
        owner = vm.addr(0x1);
        alice = vm.addr(0x2);
        bob = vm.addr(0x3);
        carol = vm.addr(0x4);

        vm.deal(owner, 1000000 ether);
        vm.deal(alice, 1000000 ether);
        vm.deal(bob, 1000000 ether);
        vm.deal(carol, 1000000 ether);

        address[] memory signatories = new address[](3);
        signatories[0] = owner;
        signatories[0] = alice;
        signatories[0] = bob;

        uint256 numOfRequiredSignatories = 2;

        multiSigWallet = new MultiSigWallet(signatories, numOfRequiredSignatories);
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExample() public {
        console2.log("Hello World");
        assertTrue(true);
    }
}
