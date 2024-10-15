import { type HardhatUserConfig } from "hardhat/config";

import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-toolbox";
import "hardhat/types/config";
import "@openzeppelin/hardhat-upgrades";
import "tsconfig-paths/register";

import "./tasks";

dotenv.config();

const config: HardhatUserConfig = {
    networks: {
        hardhat: {
            mining: {
                auto: true,
                interval: 5000,
            },
        },
    },
    solidity: {
        version: "0.8.27",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000,
            },
        },
    },
};

export default config;
