// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { ebool, einput, euint64 } from "fhevm/lib/TFHE.sol";

interface IConfidentialFungibleToken {
    event OperatorSet(address indexed holder, address indexed operator, uint48 until);
    event ConfidentialTransfer(address indexed from, address indexed to, euint64 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function tokenURI() external view returns (string memory);
    function totalSupply() external view returns (euint64);
    function balanceOf(address account) external view returns (euint64);
    function isOperator(address holder, address spender) external view returns (bool);
    function setOperator(address operator, uint48 until) external;
    function confidentialTransfer(
        address to,
        einput encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 transferred);
    function confidentialTransfer(address to, euint64 amount) external returns (euint64 transferred);
    function confidentialTransferFrom(
        address from,
        address to,
        einput encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 transferred);
    function confidentialTransferFrom(address from, address to, euint64 amount) external returns (euint64 transferred);
    function confidentialTransferAndCall(
        address to,
        einput encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) external returns (euint64 transferred);
    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) external returns (euint64 transferred);
    function confidentialTransferFromAndCall(
        address from,
        address to,
        einput encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) external returns (euint64 transferred);
    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) external returns (euint64 transferred);
    function publicTransfer(address to, uint64 amount) external returns (euint64 transferred);
    function publicTransferFrom(address from, address to, uint64 amount) external returns (euint64 transferred);
    function publicTransferAndCall(
        address to,
        uint64 amount,
        bytes calldata data
    ) external returns (euint64 transferred);
    function publicTransferFromAndCall(
        address from,
        address to,
        uint64 amount,
        bytes calldata data
    ) external returns (euint64 transferred);
}

interface IConfidentialFungibleTokenReceiver {
    function onConfidentialTransferReceived(
        address operator,
        address from,
        euint64 value,
        bytes calldata data
    ) external returns (ebool);
}
