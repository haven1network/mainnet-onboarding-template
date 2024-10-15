![Cover](.github/cover.png)

# Haven1 Testnet Developer Template

Welcome to the Haven1 Mainnet Developer Template repository! This repository
serves as a guide for developers aiming to build smart contracts on the Haven1
Mainnet. Whether you are a beginner or an experienced developer, this repository
will provide you with best practices, style recommendations, and examples to
streamline your smart contract development process.

Kindly be advised that the Haven1 development team continuously conducts
rigorous testing and refinement of all smart contracts included in this
repository. The team does not guarantee future compatibility of these contracts
until all audits are finalised and mainnet has launched (at which stage the Haven1
contracts will become a separate package).

Any future updates to this repository will be properly versioned and tagged for
clarity.

This repository utilises [Hardhat](https://hardhat.org) as the base for its
development environment. The Hardhat [documentation can be found here](https://hardhat.org/docs)
and a [tutorial can be found here](https://hardhat.org/tutorial).

## Table of Contents

-   [Introduction](#introduction)
-   [Permissioned Deployments](#permissioned-deployments)
-   [Vendor Contracts](#vendor)
    -   [H1 Developed Application](#vendor-dev-app)
    -   [Proof of Identity](#vendor-poi)
-   [Example Contracts](#examples)
    -   [Simple Storage](#examples-storage)
    -   [NFT Auction](#examples-auction)
-   [Development](#dev)
    -   [Prerequisites](#dev-pre)
    -   [Installation](#dev-install)
    -   [Project Structure](#dev-dirs)
    -   [Creating a New Contract](#dev-new-contract)
    -   [Testing and Coverage](#dev-testing)
    -   [Local Deployment](#dev-local-deploy)
    -   [Preparing for Mainnet Deployment](#dev-mainnet-deploy)
-   [Contract Submission and Review](#submission)
-   [Feedback](#feedback)

<a id="introduction"></a>

## Introduction

Haven1 is an EVM-compatible Layer 1 blockchain that seamlessly incorporates key
principles of traditional finance into the Web3 ecosystem. This repository aims
to assist developers in writing secure, efficient, and maintainable smart
contracts that will be suitable for deployment on the Haven1 Mainnet.

It provides the essential set of vendor (Haven1) contracts that developers will
need to facilitate testing and development, as well as two (2) example contracts
(a Simple Storage contract and an NFT Auction) that implement and interface with
these vendor contracts.

It provides a full testing suite with a number of helpful utility functions,
deployment scripts and tasks.

All code included in this repository has been extensively commented to make
it self-documenting and easy to comprehend.

The code within this repository establishes the expected quality for any code
submitted for review and deployment to the Haven1 Mainnet. We are dedicated to
maintaining high standards of code quality, security, and maintainability across
all smart contracts deployed on the network.

<a id="permissioned-deployments"></a>

## Permissioned Deployments

On the Haven1 Mainnet, before a contract will be considered for deployment it
must have undergone two (2) rounds of formal audit (performed by Haven1's
trusted audit partners) and be submitted to the Haven1 Association for review.
Upon successful review, _the Haven1 Association will deploy the contract on
behalf of the developer_. This process ensures a) that all contracts adhere to
the standards set by Haven1 and b) will have undergone scrutiny for security and
functionality before being deployed on the network.

To aid in the developer experience, Haven1 have authored a contract,
`H1DevelopedApplication`, that all third-party contracts deployed to the network
must implement (see [below](#vendor-dev-app) for further information on the
`H1DevelopedApplication` contract).

It, in essence, standardizes aspects of the contract deployment and upgrade
process, provides a base layer of security, provides an avenue for developers to
set function-specific fees, establishes contract privileges and ensures the
interoperability and compatibility of the contract within the broader ecosystem.

For further requirements, see [Preparing for Mainnet Deployment](#dev-mainnet-deploy).
For contract submission details, see [Contract Submission and Review](#submission).

<a id="vendor"></a>

## Vendor Contracts

This repository contains a number of vendor contracts - contracts written by
Haven1 - that are located in `./contracts/vendor/*`.

These contracts provide the necessary foundation that developers will need to
facilitate local smart contract development. Of these contracts, developers
**must** implement the `H1DevelopedApplication` contract in each contract they
seek to deploy, and may choose to interact with the `ProofOfIdentity` contract.
Accordingly, an overview of each of these contracts is provided below.

> [!NOTE]
> In addition to the two contracts described below, this repository includes
> other vendor contracts. Feel free to explore them for a deeper understanding
> of Haven1’s underlying infrastructure — they are all thoroughly commented and
> documented.
>
> These contracts are provided to enable more robust local testing, but
> interaction with them is not required.
>
> We have also included several examples demonstrating how to deploy and interact
> with these contracts. For reference, see: `./test/utils.ts`, `./test/constants.ts`,
`./test/examples/*`, `./scripts/deployLocal.ts`, and `./lib/deploy/*`.

<a id="vendor-dev-app"></a>

### H1 Developed Application

At the core of the developer experience on Haven1 is the `H1DevelopedApplication`
contract. It is an abstract contract that serves as the entry point into the
Haven1 ecosystem. It, in essence, standardizes aspects of the contract
deployment and upgrade process, provides an avenue for developers to set
function-specific fees, establishes contract privileges and ensures the
interoperability and compatibility of the contract within the broader ecosystem.

#### Core Privileges

This contract implements Open Zeppelin's `AccessControl` to establish privileges
on the contract. It establishes the following key roles:

-   `DEFAULT_ADMIN_ROLE`:  Assigned to the Haven1 Association.
-   `OPERATOR_ROLE`:       Assigned to the Haven1 Association.
-   `NETWORK_GUARDIAN`:    Assigned to the Haven1 Association and the Network Guardian Controller contract.
-   `DEV_ADMIN_ROLE`:      Assigned to the developer of the application.

#### Network Guardian

This contract implements Haven1's `NetworkGuardian` contract. It, in essence,
allows accounts with the role `NETWORK_GUARDIAN` to pause and resume operation
of the contract - a crucial feature necessary for responding to emergency
situations.

The `whenNotGuardianPaused` modifier that is exposed by `NetworkGuardian` must
also be attached to any public or external functions that modify state.

While similar in nature to Open Zeppelin's `Pausable` contract, Haven1's
`NetworkGuardian` contract provides an entirely separate API and does not
collide with any namespaces from `Pausable`. This means that developers are
free to import and use Open Zeppelin's `Pausable` contract as they see fit.

#### Contract Upgrading

This contract implements Open Zeppelin's `UUPSUpgradeable` and `Initializable`
contracts to establish the ability to upgrade the contract. Only the Haven1
Association, by virtue of the roles outlined above, will have the ability to
upgrade a contract.

Contracts built on Haven1 must be compatible with the upgrade strategy.

#### Function Fees

The account with the role `DEV_ADMIN_ROLE` is able to assign function-specific
fees via `setFee` and `setFees`. If a function has not been assigned a fee, the
minimum fee provided by the `FeeContract` will be applied to the transaction.
The unadjusted USD fee value of a given function can be viewed with `getFnFeeUSD`.
The adjusted fee in H1 tokens can be viewed with `getFnFeeAdj`.

This contract exposes a modifier - `developerFee` - that must be attached to any
public or external function that modifies state. All developer fees in the Haven1
ecosystem are taken in the network's native H1 token. This means functions that
attach the `developerFee` modifier will need to be marked as payable. Functions
that ordinarily rely on `msg.value` will now use the internal function
`msgValueAfterFee` to retrieve the remaining `msg.value` after the fee has been
deducted.

The modifier defines two parameters:
-    `payableFunction`: Indicates if the function would have been `payable`
     if not for the modifier. If true, the `msg.value` will be reduced by the
     payable fee, and developers will use the `msgValueAfterFee` function to
     retrieve the adjusted `msg.value`. If false, it is assumed that
     `msg.value` will not be used and no adjustments will be made.

-    `refundRemainingBalance`: Controls whether any remaining balance after
     function execution should be refunded to the caller. This should __not__
     be enabled in contracts that store H1 tokens, as it will inadvertently
     transfer the contract's balance to the user.

During contract initialization, developers will select whether the contract
stores native H1. As a safety measure, if `_storesH1` is marked as `true`, the
`developerFee` modifier _will not_ refund H1 to the user, even if it is set to
via `refundRemainingBalance`. The developer can request the Haven1 Association
to modify the value assigned to `_storesH1`.

Note also that the `developerFee` modifier does not allow reentrant calls.
Functions marked as `developerFee` may not call one another. In situations
where this is required, composing private functions and exposing a single
`external` entry point is recommended.

#### Example

```solidity

  function incrementCount()
      external
      payable
      whenNotGuardianPaused
      developerFee(true, false)
  {
      _count++;

      // Do something with the adjusted message value:
      _excess[msg.sender] = msgValueAfterFee();

      emit Count(msg.sender, Direction.INCR, _count);
  }
```

#### Contract Initialization

Initializing a contract that implements `H1DevelopedApplication` is an easy
process. The `initialize` function in your contract simply needs to call
`__H1DevelopedApplication_init` and provide the required arguments.

After contract initialization, the `register` function must be called to
register the contract with the Network Guardian Controller.

> [!NOTE]
> We have included a Hardhat task that will generate a new contract for you and
> handle the initial boilerplate:
>
> `npx hardhat haven-contract --name <contract-name> --path <file-path>`
>
> Eg: `npx hardhat haven-contract --name MyContract --path contracts/my-contract/MyContract.sol`

## Example
```solidity
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
```
<a id="vendor-poi"></a>

### Proof of Identity

Among the features introduced by Haven1 is the Provable Identity Framework. This
framework enhances security and unlocks previously unattainable decentralized
finance use cases, marking a significant advancement in the convergence of
traditional financial principles and decentralized technologies.

All Haven1 users will be required to complete identity verification to deter
illicit activity and enable recourse mechanisms on transactions. Once completed,
users will receive a non-transferable NFT containing anonymized information that
developers on Haven1 can utilize to permission their apps and craft novel
blockchain use cases. The `ProofOfIdentity` is responsible for setting /
updating this user information and handling the NFT issuance.

Currently tracked attributes, their ID and types:

| ID  | Attribute         | Type    | Example Return |
| --- | ----------------- | ------- | -------------- |
| 0   | primaryID         | bool    | true           |
| 1   | countryCode       | string  | "sg"           |
| 2   | proofOfLiveliness | bool    | true           |
| 3   | userType          | uint256 | 1              |
| 4   | competencyRating  | uint256 | 88             |
| 5   | nationality       | string  | "sg"           |
| 6   | idIssuingCountry  | string  | "sg"           |

Each attribute will also have a corresponding `expiry` and an `updatedAt`
field.

The following fields are guaranteed to have a non-zero entry for users who
successfully completed their identity check:

-   `primaryID`;
-   `countryCode`;
-   `proofOfLiveliness`; and
-   `userType`.


There are explicit getters for all seven (7) of the currently supported attributes.

Note that while this contract is upgradable, provisions have been made to
allow attributes to be added without the need for upgrading. An event will be
emitted (`AttributeAdded`) if an attribute is added. If an attribute is added
but the contract has not been upgraded to provide a new explicit getter,
you can use one of the four (4) generic getters to retrieve the information.

-   `getStringAttribute`;
-   `getU256Attribute`;
-   `getBoolAttribute`; and
-   `getBytesAttribute`.

**If you have a use case that requires an identity attribute that is not currently
available, please do not hesitate to contact us with your feedback and request!**

A Proof of Identity NFT can either be of type `Principal` or `Auxiliary`. The
initial Proof of Identity NFT issued to a user is of type `Principal`. All
subsequent IDs issued to that user are of type `Auxiliary`. Auxiliary IDs mirror
the attributes of the Principal and cannot themselves be updated. This system
allows a verified user to have multiple wallets active on Haven1 (up to the
maximum allowable amount).

If a user's account is suspended or unsuspended, so too are __all__ linked
accounts.

<a id="examples"></a>

## Example Contracts

This repository provides two (2) example contracts:

1.  `SimpleStorage`; and
2.  `NFTAuction`.

These contracts, located under `./contracts/examples/*`, serve as educational
resources and reference implementations for developers to aid in understanding
the integration of the `H1DevelopedApplication` contract and interaction with
the `ProofOfIdentity` contract.

The example implementations of the `H1DevelopedApplication` showcased here are
considered canonical and demonstrates best practices for initializing upgradable
contracts. Any contracts submitted for review to the Haven1 Association must
follow this pattern.

Both of these example contracts have been extensively documented.

<a id="examples-storage"></a>

### Simple Storage

The first example contract provided is the `SimpleStorage` contract
(`./contracts/examples/simple-storage/SimpleStorage.sol`). It is a minimal
contract that demonstrates storing and retrieving data on the blockchain. It
implements the `H1DevelopedApplication` contract in an idiomatic manner,
ensuring correct constructor and initialization strategies.

As noted above as a requirement, all public and external functions in this
contract have both the `whenNotGuardianPaused` and `developerFee` modifiers
attached.

As this contract does not store any native H1, the `storesH1` value can be marked
as `false` and it opts to refund users any excess H1 they send into the contract
to pay fees.

The tests and setup for this contract can be found in `./test/simple-storage/*`.
Reusable utility functions for this contract (such as the contract's deployment)
can be found in `./lib/deploy/simple-storage/deploy.ts`. We encourage developers
to follow this pattern of separation of concerns.

Developers can utilize this contract and its associated tests and utilities
as a starting point to understand the fundamental principles of developing
contracts for the Haven1 Network.

<a id="examples-auction"></a>

### NFT Auction

The second example contract provided is the `NFTAuction` contract
(`./contracts/examples/nft-auction/NFTAuction.sol`). This contract facilitates
the auction of a single NFT and demonstrates slightly more complex, but very
digestible, logic. It implements the `H1DevelopedApplication` contract in the
same manner as the `SimpleStorage` contract. Furthermore, it interfaces with the
`ProofOfIdentity` contract to permission access to the auction.

As noted above as a requirement, all public and external functions in this
contract have both the `whenNotGuardianPaused` and `developerFee` modifiers
attached.

As this contract does store native H1, it marks `storesH1` as `true` and opts
not to refund users any excess H1 they send in to pay fees.

The tests and setup for this contract can be found in `./test/nft-auction/*`.
Reusable utility functions for this contract (such as the contract's deployment)
can be found in `./utils/deploy/nft-auction/deploy.ts`. We encourage developers
to follow this pattern of separation of concerns.

<a id="dev"></a>

## Development

This section outlines everything you will need to get your local development
environment up and running. Before diving into the installation process, ensure
you have the necessary prerequisites installed on your system. Once you are
ready, follow the steps below to complete the setup of your environment.

<a id="dev-pre"></a>

### Prerequisites

-   [Node 18](https://nodejs.org/en)

<a id="dev-install"></a>

### Installation

1.  Clone the repository

    ```bash
    git clone git@github.com:haven1network/mainnet-onboarding-template.git
    ```

2.  Navigate to the repository

    ```bash
    cd path/to/repo
    ```

3.  Reinitialize git: Ensure you are in the Haven1 Developer Testnet directory
    before running this command - it will delete the `.git` directory!

    ```bash
    echo -n "Confirm .git reinit - y/N: " \
    && read ans && [ ${ans:-N} = y ] \
    && rm -rf .git && git init
    ```

4.  Install dependencies

    ```bash
    npm i
    ```

5.  Create `.env` and populate as needed.

    ```bash
    cp .env.example .env
    ```

6.  Compile contracts and generate types
    ```bash
    npx hardhat compile
    ```

<a id="dev-dirs"></a>

### Project Structure

The following top-level directory tree highlights the general project structure
and annotates important directories for clarity.

```bash
.
├── .git
├── .github
├── .gitignore
├── .prettierignore
├── .prettierrc
├── .solcover.js
├── artifacts           # Hardhat compilation artifacts
├── cache               # Hardhat cached files
├── contracts           # Source files for contracts
├── deployment_data     # Holds contract deployment data (e.g., contract addresses)
├── eslint.config.mjs
├── hardhat.config.ts   # Configuration file for the Hardhat development environment
├── lib                 # Various reusable utilities
├── node_modules
├── package-lock.json
├── package.json
├── scripts             # Workflow automations (e.g., deployment scripts)
├── tasks               # Workflow automations (e.g., verifying contracts, setting permissions)
├── test                # All project tests
├── tsconfig.json
├── typechain-types     # Output directory for contract type definitions
```

<a id="dev-new-contract"></a>

### Creating a New Contract

Creating a new contract is as easy as running the following Hardhat Task:

```bash
npx hardhat haven-contract --name <contract-name> --path <file-path>
```

For example:
```bash
npx hardhat haven-contract --name MyContract --path contracts/my-contract/MyContract.sol
```

Running this task will create a contract named `MyContract` at the
`contracts/my-contract/MyContract.sol` location. It handles declaring your new
contract along with importing, inheriting, and initializing the `H1DevelopedApplication`
contract.

If you would like to create your contract manually, that is totally okay too! See
our example contracts as a guide: `contracts/examples/*`.

> [!TIP]
> The additional security-focused contracts that Haven1 requires developers to
> implement does increase the final contract's bytecode size. To help with this,
> The maximum Smart Contract bytecode on Haven1 has been increased from 24kb to
> 100kb.

<a id="dev-testing"></a>

### Testing and Coverage

As highlighted above, tests are located and written in the `./test/*` directory.
All tests relating to a specific contract should be located in a sub-directory
and follow the `*.test.ts` naming convention. See the below example.

```bash
.
├── constants.ts                # Reusable test-specific constants (vendor contract errors etc)
├── examples
│   ├── nft-auction
│   │   ├── nftAuction.test.ts  # Test file
│   │   └── setup.ts            # Test setup file
│   └── simple-storage
│       ├── setup.ts
│       └── simpleStorage.test.ts
└── utils.ts                    # Reusable test-specific utilities (deployment logic for vendor contracts etc)
```

-   To run tests: `npm test`.
-   To run coverage: `npm run coverage`. Will output coverage results in `./coverage`.
-   To open coverage: `open ./coverage/index.html` (or: `npm run coverage:open` to run coverage and then open).

Please explore the `./test/utils.ts/`, `./test/constants.ts`, and `./lib/*`.
We have created many utilities to help you jump-start your testing. For example
usage, please see the `./test/examples/*`.

<a id="dev-local-deploy"></a>

### Local Deployment

The repository provides a local deployment script, found under
`./scripts/deployLocal.ts`, to aid to fast-tracking your developer experience.

This script contains all the setup steps for deploying the required vendor
contracts and the two (2) example contracts. It is in here that developers
can add the logic to deploy their own contracts.

To deploy locally:

1.  In one terminal instance, run the `npx hardhat node` command.
2.  In a separate terminal instance, run the `npm run deploy:local` command.

Upon successful local deployment, the contract addresses will be written to
`./deployment_data/local/*`.

<a id="dev-mainnet-deploy"></a>

### Preparing for Mainnet Deployment

There are a number of important considerations that a developer must be aware of
when preparing their contracts for submission to the Haven1 Association.

Haven1 is principally concerned with establishing high standards of code quality,
security, and maintainability across all smart contracts deployed on the network.
Projects that do not meet the requisite standards will be unable to deploy on the
Haven1 Testnet.

For ease of reference, these considerations will be broken down into points below:

1.  Ensure all contracts implement the `H1DevelopedApplication` contract
    in a manner consistent with the provided example contracts (including correct
    implementation of the `whenNotGuardianPaused` and `developerFee` modifiers
    on any public and external functions that modify state). If any contracts do
    not correctly implement the `H1DevelopedApplication` contract or are not
    being correctly initialized, the request to deploy will be denied.

2.  Ensure all contracts adhere to the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html).
    Contracts that materially deviate from this style guide will be not be
    considered for deployment (for example, 4 space indenting, preferring 80
    character line length and not exceeding 120,
    [correct ordering of functions](https://docs.soliditylang.org/en/latest/style-guide.html#order-of-functions)
    and so on).

3.  Ensure all contracts are thoroughly tested and that the test logic is clear
    and documented where necessary. Tests should follow the provided structure.
    If a project is submitted with insufficiently robust tests, if testing logic
    is not clear, or tests do not pass, the request to deploy will be denied.
    A good rule of thumb is always to prefer making code easy to read and
    understand, not just easy to write.

4.  Continue to use Typescript for any supporting code that is written. Please
    ensure strict typing of all supporting code. This will make your codebase
    easier and faster to inspect and will provide you with a greater chance of
    a successful review.

5.  Ensure every effort is made to thoroughly document your code. Whether that
    is via [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html)
    for your smart contracts, or [JSDoc](https://jsdoc.app) (where required)
    for your Typescript code. This will make your codebase easier and faster to
    inspect and will provide you with a greater chance of a successful review.

6.  Ensure deployment functions for any contracts that you wish to deploy are
    included in `./lib/deploy/*` in a manner consistent with the examples.
    Ensure that these functions are then brought in to the
    `./scripts/deployMainnet.ts` and `./scripts/deployLocal.ts` files and called
    in a manner consistent with the examples. Before deploying to Mainnet, Haven1
    will deploy your contracts locally to ensure everything runs smoothly.
    Any contracts that do not have a corresponding deployment function or an
    incorrect configuration will not be deployed.

7.  If your project requires additional environment variables, please be sure to
    include them in the `.env.example`. If the necessary environment variables
    are not supplied, we will be unable to deploy your contracts.

8.  Ensure every effort is made to remain consistent with the suggested project
    layout. This will make your codebase easier and faster to inspect, providing
    you with a higher chance of a successful review.

9.  Please feel free to override this README and use it to include any important
    information about your project!

10. If an attempt is made to include any malicious code, your account will be
    suspended and you will be excluded from any potential airdrop events.

<a id="submission"></a>

## Contract Submission and Review

To submit your contract for review, please follow these steps:

1.  Fork / clone this repository.

2.  Write your smart contract following the best practices and style guide
    recommendations provided in this repository, ensuring adherence to the
    above requirements.

3.  Once your contract is ready for review, email us a link to your public
    repository for review. Be sure to include your Haven1 verified wallet
    address that you wish to use as the contract admin. Email: `contact@haven1.org`.

4.  Our team will review your contract for security, efficiency, and adherence
    to coding standards.

5.  Upon successful review, we will deploy your contract on the Haven1 Testnet
    and notify of you the process and specifics (deployed contract addresses,
    etc). We will also PR the deployment data to your public repository.

Please note that contracts not meeting our standards will require revisions
before deployment. We aim to provide constructive feedback to help you improve
your contract's quality and security.

<a id="feedback"></a>

## Feedback

We highly value your input and strive to continuously enhance both your
experience with Haven1 and the overall developer environment. Whether your
feedback pertains to this repository, your interactions with Haven1, or any
general suggestions, please do not hesitate to submit it to us at
`contact@haven1.org`.

Each submission will be carefully reviewed, and your insights will be
instrumental in our ongoing efforts to refine Haven1 and optimize the developer
journey. Thank you for helping us build a better platform together.


