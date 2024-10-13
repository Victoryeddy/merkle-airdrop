//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract DeployMerkle is Script {
    bytes32 public s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    uint256 public s_amountToTransfer = 4 * 25 * 1e18;

    function run() external returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdropContract = new MerkleAirdrop(s_merkleRoot, address(token));
        // token.mint(token.owner(), s_amountToTransfer);
        token.mint(address(airdropContract), s_amountToTransfer);

        vm.stopBroadcast();
        return (airdropContract, token);
    }
}
