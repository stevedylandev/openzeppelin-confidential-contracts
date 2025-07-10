// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {VestingWalletCliffConfidential} from "../../finance/VestingWalletCliffConfidential.sol";

abstract contract VestingWalletCliffConfidentialMock is VestingWalletCliffConfidential, SepoliaConfig {}
