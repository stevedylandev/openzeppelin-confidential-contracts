// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { ebool, euint64 } from "fhevm/lib/TFHE.sol";

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
    function transfer(address to, euint64 amount) external returns (ebool result);
    function transferFrom(address from, address to, euint64 amount) external returns (ebool result);
    function transferAndCall(address to, euint64 amount, bytes calldata data) external returns (ebool result);
    function transferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) external returns (ebool result);
}

interface IConfidentialFungibleTokenReceiver {
    function onConfidentialTransferReceived(
        address operator,
        address from,
        euint64 value,
        bytes calldata data
    ) external returns (ebool);
}
