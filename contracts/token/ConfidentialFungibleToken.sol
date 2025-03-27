// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { TFHE, ebool, euint64 } from "fhevm/lib/TFHE.sol";
import { IConfidentialFungibleToken, IConfidentialFungibleTokenReceiver } from "./IConfidentialFungibleToken.sol";

function tryIncrease(euint64 oldValue, euint64 delta) returns (ebool success, euint64 updated) {
    euint64 newValue = TFHE.add(oldValue, delta);
    success = TFHE.ge(newValue, oldValue);
    updated = TFHE.select(success, newValue, oldValue);
}

function tryDecrease(euint64 oldValue, euint64 delta) returns (ebool success, euint64 updated) {
    success = TFHE.ge(oldValue, delta);
    updated = TFHE.select(success, TFHE.sub(oldValue, delta), oldValue);
}

abstract contract ConfidentialFungibleToken is IConfidentialFungibleToken {
    using TFHE for *;

    mapping(address holder => euint64) private _balances;
    mapping(address holder => mapping(address spender => uint48)) private _operators;
    euint64 private _totalSupply;
    string private _name;
    string private _symbol;
    string private _tokenURI;

    error InvalidReceiver(address receiver);
    error InvalidSender(address sender);
    error UnauthorizedSpender(address holder, address spender);

    constructor(string memory name_, string memory symbol_, string memory tokenURI_) {
        _name = name_;
        _symbol = symbol_;
        _tokenURI = tokenURI_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function tokenURI() public view virtual returns (string memory) {
        return _tokenURI;
    }

    function totalSupply() public view virtual returns (euint64) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (euint64) {
        return _balances[account];
    }

    function isOperator(address holder, address spender) public view virtual returns (bool) {
        return block.timestamp <= _operators[holder][spender];
    }

    function setOperator(address operator, uint48 until) public virtual {
        _setOperator(msg.sender, operator, until);
    }

    function transfer(address to, euint64 amount) public virtual returns (ebool result) {
        result = _transfer(msg.sender, to, amount);
        result.allowTransient(msg.sender);
    }

    function transferFrom(address from, address to, euint64 amount) public virtual returns (ebool result) {
        require(isOperator(from, msg.sender), UnauthorizedSpender(from, msg.sender));
        result = _transfer(from, to, amount);
        result.allowTransient(msg.sender);
    }

    function transferAndCall(address to, euint64 amount, bytes calldata data) public virtual returns (ebool result) {
        result = _transferAndCall(msg.sender, to, amount, data);
        result.allowTransient(msg.sender);
    }

    function transferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual returns (ebool result) {
        require(isOperator(from, msg.sender), UnauthorizedSpender(from, msg.sender));
        result = _transferAndCall(from, to, amount, data);
        result.allowTransient(msg.sender);
    }

    function _setOperator(address holder, address operator, uint48 until) internal virtual {
        _operators[holder][operator] = until;
        emit OperatorSet(holder, operator, until);
    }

    function _mint(address to, euint64 amount) internal returns (ebool result) {
        require(to != address(0), InvalidReceiver(address(0)));
        return _update(address(0), to, amount);
    }

    function _transfer(address from, address to, euint64 amount) internal returns (ebool result) {
        require(from != address(0), InvalidSender(address(0)));
        require(to != address(0), InvalidReceiver(address(0)));
        return _update(from, to, amount);
    }

    function _transferAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) internal returns (ebool result) {
        // Try to transfer amount + replace input with actually transferred amount.
        euint64 transferred = _transfer(from, to, amount).select(amount, 0.asEuint64());
        transferred.allowTransient(to);

        // Perform callback
        result = _checkOnERC1363TransferReceived(msg.sender, from, to, transferred, data);

        // Refund if success fails. refund should never fail
        _update(to, from, result.select(0.asEuint64(), transferred));
    }

    function _burn(address from, euint64 amount) internal returns (ebool result) {
        require(from != address(0), InvalidSender(address(0)));
        return _update(from, address(0), amount);
    }

    function _publicMint(address to, uint64 amount) internal returns (ebool result) {
        result = _mint(to, amount.asEuint64());
        // TODO: callback for public event
    }

    function _publicTransfer(address from, address to, uint64 amount) internal returns (ebool result) {
        result = _transfer(from, to, amount.asEuint64());
        // TODO: callback for public event
    }

    function _publicBurn(address from, uint64 amount) internal returns (ebool result) {
        result = _burn(from, amount.asEuint64());
        // TODO: callback for public event
    }

    function _update(address from, address to, euint64 amount) internal virtual returns (ebool result) {
        euint64 ptr;

        if (from == address(0)) {
            (result, ptr) = tryIncrease(_totalSupply, amount);
            ptr.allowThis();
            _totalSupply = ptr;
        } else {
            (result, ptr) = tryDecrease(_balances[from], amount);
            ptr.allowThis();
            ptr.allow(to);
            _balances[from] = ptr;
        }

        euint64 transferred = result.select(amount, 0.asEuint64());

        if (to == address(0)) {
            ptr = _totalSupply.sub(transferred);
            ptr.allowThis();
            _totalSupply = ptr;
        } else {
            ptr = _balances[to].add(transferred);
            ptr.allowThis();
            ptr.allow(to);
            _balances[to] = ptr;
        }

        if (from != address(0)) transferred.allow(from);
        if (to != address(0)) transferred.allow(to);
        emit ConfidentialTransfer(from, to, transferred);
    }

    // TODO: move to utils library ?
    function _checkOnERC1363TransferReceived(
        address operator,
        address from,
        address to,
        euint64 value,
        bytes calldata data
    ) private returns (ebool) {
        if (to.code.length > 0) {
            try
                IConfidentialFungibleTokenReceiver(to).onConfidentialTransferReceived(operator, from, value, data)
            returns (ebool retval) {
                return retval;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert InvalidReceiver(to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true.asEbool();
        }
    }
}
