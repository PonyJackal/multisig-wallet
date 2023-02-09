// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployMultiSigWallet is Script {
    MultiSigWallet internal multiSigWallet;

    function run() public {
        vm.startBroadcast();

        address[] memory signatories = new address[](3);
        signatories[0] = 0xE078c3BDEe620829135e1ab526bE860498B06339;
        signatories[1] = 0x63E7a1983b01E3275887E5eB7DEB7930aee2FFc4;
        signatories[2] = 0xFB6c5feE537344Db0f585d65C684fbc2A800d0a8;

        uint256 numOfRequiredSignatories = 2;
        multiSigWallet = new MultiSigWallet(signatories, numOfRequiredSignatories);
        vm.stopBroadcast();
    }
}
