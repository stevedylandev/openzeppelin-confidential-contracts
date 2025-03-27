// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { TFHE, ebool, euint64 } from "fhevm/lib/TFHE.sol";
import { IConfidentialFungibleTokenReceiver } from "../token/IConfidentialFungibleToken.sol";
import { ConfidentialFungibleToken } from "../token/ConfidentialFungibleToken.sol";

contract ConfidentialFungibleTokenMock is ConfidentialFungibleToken {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) ConfidentialFungibleToken(name_, symbol_, tokenURI_) {}

    function $_setOperator(address holder, address operator, uint48 until) public virtual {
        return _setOperator(holder, operator, until);
    }

    function $_mint(address to, euint64 amount) public returns (ebool result) {
        return _mint(to, amount);
    }

    function $_transfer(address from, address to, euint64 amount) public returns (ebool result) {
        return _transfer(from, to, amount);
    }

    function $_transferAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public returns (ebool result) {
        return _transferAndCall(from, to, amount, data);
    }

    function $_burn(address from, euint64 amount) public returns (ebool result) {
        return _burn(from, amount);
    }

    function $_publicMint(address to, uint64 amount) public returns (ebool result) {
        return _publicMint(to, amount);
    }

    function $_publicTransfer(address from, address to, uint64 amount) public returns (ebool result) {
        return _publicTransfer(from, to, amount);
    }

    function $_publicBurn(address from, uint64 amount) public returns (ebool result) {
        return _publicBurn(from, amount);
    }

    function $_update(address from, address to, euint64 amount) public virtual returns (ebool result) {
        return _update(from, to, amount);
    }
}

contract ConfidentialFungibleTokenReceiverMock is IConfidentialFungibleTokenReceiver {
    uint64 private _threshold;

    event ConfidentialTransferReceived(address token, address operator, address from, euint64 value, bytes data);

    constructor(uint64 threshold) {
        _threshold = threshold;
    }

    function onConfidentialTransferReceived(
        address operator,
        address from,
        euint64 value,
        bytes calldata data
    ) external returns (ebool) {
        emit ConfidentialTransferReceived(msg.sender, operator, from, value, data);
        return TFHE.ge(value, _threshold);
    }
}
