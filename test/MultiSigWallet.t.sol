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
        signatories[1] = alice;
        signatories[2] = bob;

        uint256 numOfRequiredSignatories = 2;

        vm.startPrank(owner);
        multiSigWallet = new MultiSigWallet(signatories, numOfRequiredSignatories);
        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testAddSignatory() public {
        vm.startPrank(owner);
        // add carol as a new signatory
        multiSigWallet.addSignatory(carol);
        // check if carol is a signatory
        bool isCarolSignatory = multiSigWallet.isSignatory(carol);
        assertEq(isCarolSignatory, true);

        // tried to add alice as a signatory
        vm.expectRevert("MultiSigWallet: Signatory already exists");
        multiSigWallet.addSignatory(alice);

        vm.stopPrank();

        vm.startPrank(alice);
        // alice, not owner, tried to add alice as a signatory
        vm.expectRevert("Ownable: caller is not the owner");
        multiSigWallet.addSignatory(bob);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testRemoveSignatory() public {
        vm.startPrank(owner);
        // remove alice as a new signatory
        multiSigWallet.removeSignatory(alice);
        // check if alice is a signatory
        bool isAliceSignatory = multiSigWallet.isSignatory(alice);
        assertEq(isAliceSignatory, false);

        // tried to remove carol as a signatory
        vm.expectRevert("MultiSigWallet: Signatory doesn't exist");
        multiSigWallet.removeSignatory(carol);

        vm.stopPrank();

        vm.startPrank(alice);
        // alice, not owner, tried to add alice as a signatory
        vm.expectRevert("Ownable: caller is not the owner");
        multiSigWallet.removeSignatory(bob);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testUpdateNumOfRequiredSignatories() public {
        vm.startPrank(owner);
        // update a numOfRequiredSignatories
        multiSigWallet.updateNumOfRequiredSignatories(2);
        // check numOfRequiredSignatories
        uint256 numOfRequiredSignatories = multiSigWallet.numOfRequiredSignatories();
        assertEq(numOfRequiredSignatories, 2);

        vm.stopPrank();

        vm.startPrank(alice);
        // alice, not owner, tried to add alice as a signatory
        vm.expectRevert("Ownable: caller is not the owner");
        multiSigWallet.updateNumOfRequiredSignatories(3);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testSetRecoveryAddress() public {
        vm.startPrank(owner);
        // set carol as a recovery address
        multiSigWallet.setRecoveryAddress(carol);

        // trie to set zero address as a recovery address
        vm.expectRevert("MultiSigWallet: Invalid address");
        multiSigWallet.setRecoveryAddress(address(0));
        vm.stopPrank();

        vm.startPrank(alice);
        // alice, not owner, tried to add alice as a signatory
        vm.expectRevert("Ownable: caller is not the owner");
        multiSigWallet.setRecoveryAddress(carol);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testSubmitTransaction() public {
        vm.startPrank(alice);
        // alice submit a transaction
        multiSigWallet.submitTransaction(carol, 1 ether, "");
        (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numOfConfirmations
        ) = multiSigWallet.transactions(0);
        assertEq(destination, carol);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(numOfConfirmations, 0);

        vm.stopPrank();

        vm.startPrank(carol);
        // carol, not a signatory, tried to submit a transaction
        vm.expectRevert("MultiSigWallet: Not a signatory");
        multiSigWallet.submitTransaction(carol, 1 ether, "");

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testConfrimTransaction() public {
        vm.startPrank(alice);
        // alice submit a transaction
        vm.expectRevert("MultiSigWallet: Transaction doesn't exist");
        multiSigWallet.confirmTransaction(0);

        multiSigWallet.submitTransaction(carol, 1 ether, "");
        multiSigWallet.confirmTransaction(0);

        (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numOfConfirmations
        ) = multiSigWallet.transactions(0);
        assertEq(destination, carol);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(numOfConfirmations, 1);

        vm.expectRevert("MultiSigWallet: Already confirmed");
        multiSigWallet.confirmTransaction(0);

        vm.stopPrank();

        vm.startPrank(carol);
        // carol, not a signatory, tried to submit a transaction
        vm.expectRevert("MultiSigWallet: Not a signatory");
        multiSigWallet.confirmTransaction(0);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testRevokeTransaction() public {
        vm.startPrank(alice);
        // alice submit a transaction
        vm.expectRevert("MultiSigWallet: Transaction doesn't exist");
        multiSigWallet.revokeTransaction(0);

        multiSigWallet.submitTransaction(carol, 1 ether, "");

        vm.expectRevert("MultiSigWallet: Not confirmed");
        multiSigWallet.revokeTransaction(0);

        multiSigWallet.confirmTransaction(0);
        multiSigWallet.revokeTransaction(0);
        (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numOfConfirmations
        ) = multiSigWallet.transactions(0);
        assertEq(destination, carol);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(numOfConfirmations, 0);

        vm.stopPrank();

        vm.startPrank(carol);
        // carol, not a signatory, tried to submit a transaction
        vm.expectRevert("MultiSigWallet: Not a signatory");
        multiSigWallet.revokeTransaction(0);

        vm.stopPrank();
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExecuteTransaction() public {
        vm.startPrank(alice);
        // alice submit a transaction
        vm.expectRevert("MultiSigWallet: Transaction doesn't exist");
        multiSigWallet.executeTransaction(0);

        multiSigWallet.submitTransaction(carol, 1 ether, "");
        multiSigWallet.confirmTransaction(0);

        vm.expectRevert("MultiSigWallet: Cannot execute transaction");
        multiSigWallet.executeTransaction(0);

        vm.stopPrank();

        vm.startPrank(bob);
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner);
        multiSigWallet.confirmTransaction(0);

        vm.expectRevert("MultiSigWallet: Transaction failed");
        multiSigWallet.executeTransaction(0);

        address payable mutisigWalletAddress = payable(address(multiSigWallet));
        mutisigWalletAddress.transfer(2 ether);

        multiSigWallet.executeTransaction(0);

        (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numOfConfirmations
        ) = multiSigWallet.transactions(0);
        assertEq(destination, carol);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, true);
        assertEq(numOfConfirmations, 3);

        vm.expectRevert("MultiSigWallet: Already executed");
        multiSigWallet.executeTransaction(0);

        vm.stopPrank();

        vm.startPrank(carol);
        // carol, not a signatory, tried to submit a transaction
        vm.expectRevert("MultiSigWallet: Not a signatory");
        multiSigWallet.confirmTransaction(0);

        vm.stopPrank();
    }
}
