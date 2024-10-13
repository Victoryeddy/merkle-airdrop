//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    //this contract will have list of addresses and people will be able to claim their ERC20 token

    using SafeERC20 for IERC20;

    error MerkleAirdrop__FailedToVerify();
    error MerkleAirdrop__hasClaimedToken(address account, bool status);
    error MerkleAirdrop__InvalidSignature();

    event Claim(address indexed account, uint256 indexed amountToClaim);

    address[] private s_claimers;
    bytes32 private immutable i_merkleRoot;

    IERC20 private immutable i_airdropToken;

    mapping(address account => bool hasClaimed) private s_claimStatus;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 merkleRoot, address airdropToken) EIP712("Merkle Airdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = IERC20(airdropToken);
    }

    function claim(
        address account,
        uint256 amountToClaim,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (s_claimStatus[account]) {
            revert MerkleAirdrop__hasClaimedToken(account, s_claimStatus[account]);
        }

        if (!_isValidSignature(account, getMessageHash(account, amountToClaim), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // A leaf represents a hash of single data
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amountToClaim))));

        //We check to see if the leaf is part of the merkle tree
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) revert MerkleAirdrop__FailedToVerify();

        s_claimStatus[account] = true;
        emit Claim(account, amountToClaim);

        i_airdropToken.safeTransfer(account, amountToClaim);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        //**This function is called from EIP712 which helps to get the digest for an account*/
        //** A digest is just a snapshot or digital summary of a piece of data */
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim(account, amount))));
    }

    //** Getter Functions */

    function getToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getClaimStatus(address account) external view returns (bool) {
        return s_claimStatus[account];
    }

    function _isValidSignature(
        address account,
        bytes32 digest,
        /**
         * digest is the message gotten from combining account + amount
         */
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
