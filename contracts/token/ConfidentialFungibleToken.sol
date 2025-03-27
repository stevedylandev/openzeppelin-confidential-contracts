// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { TFHE, ebool, euint256 } from "fhevm/lib/TFHE.sol";

interface IConfidentialFungibleTokenReceiver {
    function onConfidentialTransferReceived(address operator, address from, euint256 value, bytes calldata data) external returns (ebool);
}

abstract contract ConfidentialFungibleToken {
    using TFHE for *;

    mapping(address holder => euint256) private _balances;
    mapping(address holder => mapping(address spender => uint48)) private _operators;
    euint256 private _totalSupply;
    string private _name;
    string private _symbol;
    string private _tokenURI;

    event OperatorSet(address indexed holder, address indexed operator, uint48 until);
    event ConfidentialTransfer(address indexed from, address indexed to, euint256 amount);

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

    function totalSupply() public view virtual returns (euint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (euint256) {
        return _balances[account];
    }

    function isOperator(address holder, address spender) public view virtual returns (bool) {
        return block.timestamp <= _operators[holder][spender];
    }

    function setOperator(address operator, uint48 until) public virtual {
        _setOperator(msg.sender, operator, until);
    }

    function transfer(address to, euint256 amount) public virtual returns (euint256 result) {
        result = _transfer(msg.sender, to, amount);
        result.allowTransient(msg.sender);
    }

    function transferFrom(address from, address to, euint256 amount) public virtual returns (euint256 result) {
        require(isOperator(from, msg.sender), UnauthorizedSpender(from, msg.sender));
        result = _transfer(from, to, amount);
        result.allowTransient(msg.sender);
    }

    function transferAndCall(address to, euint256 amount, bytes calldata data) public virtual returns (euint256 result) {
        result = _transferAndCall(msg.sender, to, amount, data);
        result.allowTransient(msg.sender);
    }

    function transferFromAndCall(address from, address to, euint256 amount, bytes calldata data) public virtual returns (euint256 result) {
        require(isOperator(from, msg.sender), UnauthorizedSpender(from, msg.sender));
        result = _transferAndCall(from, to, amount, data);
        result.allowTransient(msg.sender);
    }

    function _setOperator(address holder, address operator, uint48 until) internal virtual {
        _operators[holder][operator] = until;
        emit OperatorSet(holder, operator, until);
    }

    function _mint(address to, euint256 amount) internal returns (euint256 result) {
        require(to != address(0), InvalidReceiver(address(0)));
        return _update(address(0), to, amount);
    }

    function _transfer(address from, address to, euint256 amount) internal returns (euint256 result) {
        require(from != address(0), InvalidSender(address(0)));
        require(to != address(0), InvalidReceiver(address(0)));
        return _update(from, to, amount);
    }

    function _transferAndCall(address from, address to, euint256 amount, bytes calldata data) internal returns (euint256 result) {
        // Try to transfer amount + replace input with actually transferred amount.
        amount = _transfer(from, to, amount);
        amount.allowTransient(to);

        // Perform callback
        result = _checkOnERC1363TransferReceived(msg.sender, from, to, amount, data)
            .select(amount, 0.asEuint256());

        // Refund if success fails. refund should never fail
        _update(to, from, amount.sub(result));
    }

    function _burn(address from, euint256 amount) internal returns (euint256 result) {
        require(from != address(0), InvalidSender(address(0)));
        return _update(from, address(0), amount);
    }

    function _publicMint(address to, uint80 amount) internal returns (euint256 result) {
        result = _mint(to, amount.asEuint256());
        // TODO: callback for public event
    }

    function _publicTransfer(address from, address to, uint80 amount) internal returns (euint256 result) {
        result = _transfer(from, to, amount.asEuint256());
        // TODO: callback for public event
    }

    function _publicBurn(address from, uint80 amount) internal returns (euint256 result) {
        result = _burn(from, amount.asEuint256());
        // TODO: callback for public event
    }

    function _update(address from, address to, euint256 amount) internal virtual returns (euint256 result) {
        // TODO: consider totalSupply overflow as a failure case when minting
        result = (
            from == address(0)
                ? true.asEbool()
                : _balances[from].ge(amount)
        ).select(amount, 0.asEuint256());

        if (from == address(0)) {
            euint256 ptr = _totalSupply = _totalSupply.add(result);
            ptr.allowThis();
        } else {
            euint256 ptr = _balances[from] = _balances[from].sub(result);
            ptr.allowThis();
            ptr.allow(to);
        }

        if (to == address(0)) {
            euint256 ptr = _totalSupply = _totalSupply.sub(result);
            ptr.allowThis();
        } else {
            euint256 ptr = _balances[to] = _balances[to].add(result);
            ptr.allowThis();
            ptr.allow(to);
        }

        emit ConfidentialTransfer(from, to, result);
    }

    function _checkOnERC1363TransferReceived(
        address operator,
        address from,
        address to,
        euint256 value,
        bytes calldata data
    ) private returns (ebool) {
        if (to.code.length > 0) {
            try IConfidentialFungibleTokenReceiver(to).onConfidentialTransferReceived(operator, from, value, data) returns (ebool retval) {
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