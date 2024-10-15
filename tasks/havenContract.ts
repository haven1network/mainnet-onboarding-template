import { task, types } from "hardhat/config";
import path from "path";
import fs from "fs";

function generateImportStatement(outputFilePath: string) {
    const p =
        "contracts/vendor/h1-developed-application/H1DevelopedApplication.sol";

    // Generate the relative path
    const relativePath = path.relative(path.dirname(outputFilePath), p);

    // Convert it to Unix-style paths for Solidity imports
    const unixPath = relativePath.split(path.sep).join("/");

    // Create the import statement
    return `import { H1DevelopedApplication } from "${unixPath}";`;
}

function template(name: string, filePath: string) {
    const contract = `// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

${generateImportStatement(filePath)}

/**
 * @title ${name}
 *
 * @author <Your name here>
 *
 * @notice <Description here>
 */
contract ${name} is H1DevelopedApplication {
    /* TYPE DECLARATIONS
    ==================================================*/

    /* STATE VARIABLES
    ==================================================*/

    /* EVENTS
    ==================================================*/

    /* ERRORS
    ==================================================*/

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* Initialize
    ========================================*/

    /**
     * @notice Initializes the \`${name}\` contract.
     *
     * @param feeContract           The Fee Contract address.
     * @param guardianController    The Network Guardian Controller address.
     * @param association           The Haven1 Association address.
     * @param developer             The address of the contract's developer.
     * @param feeCollector          The address of the developer's fee collector.
     * @param fnSigs                Function signatures for which fees will be set.
     * @param fnFees                Fees that will be set for their \`fnSigs\` counterparts.
     * @param storesH1              Whether this contract stores native H1.
     */
    function initialize(
        address feeContract,
        address guardianController,
        address association,
        address developer,
        address feeCollector,
        string[] memory fnSigs,
        uint256[] memory fnFees,
        bool storesH1
    ) external initializer {
        __H1DevelopedApplication_init(
            feeContract,
            guardianController,
            association,
            developer,
            feeCollector,
            fnSigs,
            fnFees,
            storesH1
        );
    }

    /* External
    ========================================*/

    /* Public
    ========================================*/

    /* Internal
    ========================================*/

    /* Private
    ========================================*/
}

`;

    return contract;
}

const cross = "\u2715";
const check = "\u2713";

/**
 * Task responsible for generating a new Haven1 Contract.
 *
 * @example
 * npx hardhat haven-contract --name <name> --path <path>
 */
task("haven-contract", "Generates a new Haven1 Contract")
    .addParam("name", "The name of the contract", "", types.string)
    .addParam("path", "The relative file path", "", types.string)
    .setAction(async function (args) {
        console.log("Checking Args");

        const contract = args.name as string;
        const p = path.join(process.cwd(), args.path);

        if (!contract) {
            console.error(`\t ${cross} Error: Contract name must be supplied.`);
            process.exit(1);
        }

        if (!p.endsWith(".sol")) {
            console.error(`\t ${cross} Error: A valid path must be supplied.`);
            console.error(
                `\t ${cross} Got: ${args.path}. Expected a path that ends with .sol`
            );
            process.exit(1);
        }

        const fileExists = fs.existsSync(p);

        if (fileExists) {
            console.error(`\t ${cross} File: ${p} already exists.`);
            process.exit(1);
        }

        console.log(`\t ${check} Success\n`);

        const dir = path.dirname(p);

        const dirExists = fs.existsSync(dir);

        if (!dirExists) {
            console.log(`Creating Directory: ${dir}`);
            fs.mkdirSync(dir, { recursive: true });
            console.log(`\t ${check} Success\n`);
        }

        console.log(`Generating Contract: ${contract}`);
        const text = template(contract, p);
        fs.writeFileSync(p, text, "utf8");
        console.log(`\t ${check} Success`);
    });
