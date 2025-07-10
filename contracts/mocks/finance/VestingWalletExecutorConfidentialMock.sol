// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {VestingWalletExecutorConfidential} from "../../finance/VestingWalletExecutorConfidential.sol";

abstract contract VestingWalletExecutorConfidentialMock is VestingWalletExecutorConfidential, SepoliaConfig {}
