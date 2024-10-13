//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";
import {BagelToken} from "../../src/BagelToken.sol";

import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

import {DeployMerkle} from "../../script/DeployMerkle.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public ma;
    BagelToken public bToken;

    DeployMerkle public dMerkle;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    uint256 public constant AMOUNT = 25 * 1e18;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] public PROOF = [proofOne, proofTwo];

    uint256 public constant INITIAL_AMOUNT = AMOUNT * 4;

    address userTwo;

    address user;
    uint256 userPrivateKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            dMerkle = new DeployMerkle();
            (ma, bToken) = dMerkle.run();
        } else {
            bToken = new BagelToken();
            ma = new MerkleAirdrop(ROOT, address(bToken));
            bToken.mint(address(ma), INITIAL_AMOUNT);
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
        userTwo = makeAddr("userTwo");
    }

    function testUsersCanClaim() public {
        uint256 startingBalanceOfUser = bToken.balanceOf(user);

        bytes32 digest = ma.getMessageHash(user, AMOUNT);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(userTwo);
        ma.claim(user, AMOUNT, PROOF, v, r, s);

        uint256 endingBalanceOfUser = bToken.balanceOf(user);

        console.log(ma.getClaimStatus(user));
        console.log(endingBalanceOfUser, " user balance");
        console.log(bToken.balanceOf(address(ma)), "ma balance");
        assert(endingBalanceOfUser + startingBalanceOfUser == AMOUNT);
    }
}
