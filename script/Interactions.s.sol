//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdrop__IncorrectSignatureLength();

    address public CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public CLAIMING_AMOUNT = 25 * 1e18;

    bytes32 proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [proofOne, proofTwo];

    bytes private SIGNATURE =
        hex"b128f041fffd5b8b34062d62329a359b42e5b4b97a6df21874b20a6cd0db837048a93891091c9f93788781bdcf8011b296fb2e51f935b255ea5dc223208e63661b";

    function claimAirdrop(address mostRecentMerkleAddress, address mostRecentBagelToken) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(mostRecentMerkleAddress).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
        uint256 balanceOfClaimer = BagelToken(mostRecentBagelToken).balanceOf(CLAIMING_ADDRESS);
        console.log(balanceOfClaimer, "Balance of Claimer");
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdrop__IncorrectSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployedMerkleAddress =
            DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        address mostRecentlyDeployedBagelTokenAddress =
            DevOpsTools.get_most_recent_deployment("BagelToken", block.chainid);
        claimAirdrop(mostRecentlyDeployedMerkleAddress, mostRecentlyDeployedBagelTokenAddress);
    }
}
