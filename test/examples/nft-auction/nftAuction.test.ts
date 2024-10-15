/* IMPORT NODE MODULES
================================================== */
import {
    loadFixture,
    time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { parseUnits } from "ethers";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { TestDeployment, UserType, auctionErr } from "./setup";
import {
    DAY_SEC,
    ZERO_ADDRESS,
    accessControlErr,
    addressErr,
    guardianErr,
    h1DevelopedErr,
    initialiazbleErr,
} from "../../constants";
import { PROOF_OF_ID_ATTRS } from "@lib/deploy/proof-of-identity";
import {
    type NFTAuctionArgs,
    deployNFTAuction,
    AuctionID,
} from "@lib/deploy/nft-auction";

import { tsFromTxRec } from "@lib/tx";
import { fnSelector } from "@lib/fnSelector";
import { getH1Balance } from "@lib/token";

/* TESTS
================================================== */
describe("NFT Auction", function () {
    /* Setup
    ======================================== */
    const bidSel = fnSelector("bid()");

    async function setup() {
        return await TestDeployment.create();
    }

    /* Deployment and Initialization
    ======================================== */
    describe("Deployment and Initialization", function () {
        it("Should have a deployment address", async function () {
            const t = await loadFixture(setup);
            expect(t.auctionAddress).to.have.length(42);
        });

        it("Should correctly set the auction kind", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionArgs.config;
            const auctionType = await t.auction.auctionKind();
            expect(auctionType).to.equal(cfg.kind);
        });

        it("Should correctly set the auction length", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionArgs.config;
            const auctionLength = await t.auction.auctionLength();
            expect(auctionLength).to.equal(cfg.length);
        });

        it("Should correctly set the starting bid", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionArgs.config;
            const startingBid = await t.auction.highestBid();
            expect(startingBid).to.equal(cfg.startingBid);
        });

        it("Should correctly set the prize NFT address and ID", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionArgs.config;
            const [addr, id] = await t.auction.nft();
            expect(addr).to.equal(cfg.nft);
            expect(id).to.equal(cfg.nftID);
        });

        it("Should correctly set the auction beneficiary address and ID", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionArgs.config;
            const b = await t.auction.beneficiary();
            expect(b).to.equal(cfg.beneficiary);
            expect(b).to.equal(t.auctionArgs.developer);
        });

        it("Should fail to init if the POI address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionArgs = {
                ...t.auctionArgs,
                proofOfIdentity: ZERO_ADDRESS,
            };

            const err = addressErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association)
            ).to.be.revertedWithCustomError(t.auction, err);
        });

        it("Should fail to init if an auction kind of zero (0) is supplied ", async function () {
            const t = await loadFixture(setup);
            const kind = 0;
            const args = t.auctionArgs;
            const cfg = { ...args.config, kind };
            const err = auctionErr("INVALID_AUCTION_KIND");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.proofOfIdentity,
                        args.feeContract,
                        args.guardianController,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(0);
        });

        it("Should fail to deploy if an auction kind greater than three (3) is supplied ", async function () {
            const t = await loadFixture(setup);
            const kind = 4;
            const args = t.auctionArgs;
            const cfg = { ...args.config, kind };
            const err = auctionErr("INVALID_AUCTION_KIND");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.proofOfIdentity,
                        args.feeContract,
                        args.guardianController,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(kind);
        });

        it("Should fail to deploy if an invalid auction length is supplied", async function () {
            const t = await loadFixture(setup);
            const length = 0;
            const args = t.auctionArgs;
            const cfg = { ...args.config, length };
            const err = auctionErr("INVALID_AUCTION_LENGTH");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.proofOfIdentity,
                        args.feeContract,
                        args.guardianController,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(length, DAY_SEC);
        });

        it("Should fail to deploy if an invalid NFT address is supplied", async function () {
            const t = await loadFixture(setup);
            const nft = ZERO_ADDRESS;
            const args = t.auctionArgs;
            const cfg = { ...args.config, nft };
            const err = addressErr("ZERO_ADDRESS");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.proofOfIdentity,
                        args.feeContract,
                        args.guardianController,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            ).to.be.revertedWithCustomError(f, err);
        });

        it("Should fail to deploy if an invalid beneficiary is supplied", async function () {
            const t = await loadFixture(setup);
            const beneficiary = ZERO_ADDRESS;
            const args = t.auctionArgs;
            const cfg = { ...args.config, beneficiary };
            const err = addressErr("ZERO_ADDRESS");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.proofOfIdentity,
                        args.feeContract,
                        args.guardianController,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            ).to.be.revertedWithCustomError(f, err);
        });

        it("Should not allow initialize to be called a second time", async function () {
            const t = await loadFixture(setup);

            const c = t.auction;
            const a = t.auctionArgs;
            const err = initialiazbleErr("ALREADY_INITIALIZED");

            await expect(
                c.initialize(
                    a.proofOfIdentity,
                    a.feeContract,
                    a.guardianController,
                    a.association,
                    a.developer,
                    a.feeCollector,
                    a.fnSigs,
                    a.fnFees,
                    a.config
                )
            ).to.be.revertedWith(err);
        });
    });

    /* Starting an Auction
    ======================================== */
    describe("Starting an Auction", function () {
        it("Should only allow the dev to start an auction", async function () {
            const t = await loadFixture(setup);
            const c = t.auction;
            const cDev = c.connect(t.developer);
            const err = accessControlErr("MISSING_ROLE");

            await expect(c.startAuction()).to.be.revertedWith(err);
            await expect(cDev.startAuction()).to.not.be.reverted;
        });

        it("Should revert if the auction has already been started", async function () {
            const t = await loadFixture(setup);
            const c = t.auction.connect(t.developer);
            const err = auctionErr("ACTIVE");

            const txRes = await c.startAuction();
            txRes.wait();

            await expect(c.startAuction()).to.be.revertedWithCustomError(
                c,
                err
            );
        });

        it("Should transfer in the prize NFT", async function () {
            const t = await loadFixture(setup);
            const c = t.auction.connect(t.developer);

            const txRes = await c.startAuction();
            txRes.wait();

            const bal = await t.nft.balanceOf(t.auctionAddress);
            expect(bal).to.equal(1);
        });

        it("Should emit an `AuctionStarted` event", async function () {
            const t = await loadFixture(setup);
            const c = t.auction.connect(t.developer);
            const event = "AuctionStarted";

            await expect(c.startAuction()).to.emit(c, event);
        });

        it("Should revert if the contract is paused", async function () {
            const t = await loadFixture(setup);
            const c = t.auction;
            const cDev = t.auction.connect(t.developer);
            const err = guardianErr("PAUSED");

            const isPaused = await c.guardianPaused();
            expect(isPaused).to.be.false;

            let txRes = await c.guardianPause();
            await txRes.wait();

            // Case: contract is paused
            await expect(cDev.startAuction()).to.be.revertedWithCustomError(
                c,
                err
            );

            // Case: contract is not paused
            txRes = await c.guardianUnpause();
            await txRes.wait();
            await expect(cDev.startAuction()).to.not.be.reverted;
        });
    });

    /* Placing Bids
    ======================================== */
    describe("Placing Bids", function () {
        it("Should correctly place a bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cfg = t.auctionArgs.config;
            const cDev = t.auction.connect(t.developer);

            const cUser = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];

            const bid = parseUnits("15");
            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start the auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            const hasStarted = await t.auction.hasStarted();
            expect(hasStarted).to.be.true;

            // Initial Bid State
            let highestBid = await cDev.highestBid();
            expect(highestBid).to.equal(cfg.startingBid);

            let highestBidder = await cDev.highestBidder();
            expect(highestBidder).to.equal(ZERO_ADDRESS);

            // User places a bid
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            highestBid = await cDev.highestBid();
            expect(highestBid).to.equal(bid);

            highestBidder = await cDev.highestBidder();
            expect(highestBidder).to.equal(addr);
        });

        it("Should revert if the fee is insufficient", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const fee = await cDev.getFnFeeAdj(bidSel);

            const errFunds = h1DevelopedErr("INSUFFICIENT_FUNDS");
            const errValue = auctionErr("ZERO_VALUE");

            await t.poi.issueDefaultIdentity(addr);

            // Start the auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            const hasStarted = await cDev.hasStarted();
            expect(hasStarted).to.be.true;

            // Place bid with no value at all
            await expect(cUser.bid())
                .to.be.revertedWithCustomError(cUser, errFunds)
                .withArgs(0n, fee);

            // Place bid with no value after fee
            await expect(
                cUser.bid({ value: fee })
            ).to.be.revertedWithCustomError(cUser, errValue);
        });

        it("Should revert if the auction has not started", async function () {
            // Setup
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const bid = parseUnits("4", 18);
            const err = auctionErr("NOT_STARTED");
            const fee = await c.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            await expect(
                c.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the auction has finished", async function () {
            // Setup
            const t = await loadFixture(setup);
            const len = t.auctionArgs.config.length;

            const cDev = t.auction.connect(t.developer);

            const cUser = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const bid = parseUnits("100", 18);

            const err = auctionErr("FINISHED");

            const fee = await cUser.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start the auction and advance past the end time.
            const txRes = await cDev.startAuction();
            await txRes.wait();
            await time.increase(len + 1n);

            const hasFinished = await cUser.hasFinished();
            expect(hasFinished).to.be.true;

            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should revert if the bid is too low", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);

            const cUser = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const bid = t.auctionArgs.config.startingBid / 2n;

            const fee = await cUser.getFnFeeAdj(bidSel);

            const err = auctionErr("BID_TOO_LOW");

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // Place insufficient bid
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should revert if the new bid is the same as the current highest bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);

            const cUser = t.auction.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const bid = t.auctionArgs.config.startingBid;

            const fee = await cUser.getFnFeeAdj(bidSel);

            const err = auctionErr("BID_TOO_LOW");

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // Place a bid equal to the current highest bid.
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should not allow the current highest bidder to outbid themselves / raise thier bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bidOne = parseUnits("15", 18);
            const bidTwo = parseUnits("16", 18);

            const err = auctionErr("IS_HIGHEST");

            const fee = await cUser.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // First bid
            txRes = await cUser.bid({ value: bidOne + fee });
            await txRes.wait();

            // Second bid
            await expect(
                cUser.bid({ value: bidTwo + fee })
            ).to.revertedWithCustomError(cUser, err);
        });

        it("Should refund the previous highest bid to the previous highest bidder upon a new successful bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUserOne = t.auction.connect(t.accounts[0]);
            const cUserTwo = t.auction.connect(t.accounts[1]);

            const addrOne = t.accountAddresses[0];
            const addrTwo = t.accountAddresses[1];

            const bidOne = parseUnits("15", 18);
            const bidTwo = parseUnits("16", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addrOne);
            await t.poi.issueDefaultIdentity(addrTwo);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // First user bids
            txRes = await cUserOne.bid({ value: bidOne + fee });
            await txRes.wait();

            const userOneBalBefore = await getH1Balance(addrOne);

            // Second user bids
            txRes = await cUserTwo.bid({ value: bidTwo + fee });
            await txRes.wait();

            const userOneBalAfter = await getH1Balance(addrOne);
            expect(userOneBalAfter).to.equal(userOneBalBefore + bidOne);
        });

        it("Should correctly update the highest bidder and highest bid", async function () {
            // Setup
            const t = await loadFixture(setup);
            const startBid = t.auctionArgs.config.startingBid;

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("81", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            //  Initial State
            const prevBidder = await cDev.highestBidder();
            const prevBid = await cDev.highestBid();

            expect(prevBidder).to.equal(ZERO_ADDRESS);
            expect(prevBid).to.equal(startBid);

            // User bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            const currBidder = await cDev.highestBidder();
            const currBid = await cDev.highestBid();

            expect(currBidder).to.equal(addr);
            expect(currBid).to.equal(bid);
        });

        it("Should revert if the contract is paused", async function () {
            // Setup
            const t = await loadFixture(setup);
            const c = t.auction;

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("81", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);
            const err = guardianErr("PAUSED");

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // Initial State
            const isPaused = await c.guardianPaused();
            expect(isPaused).to.be.false;

            // pause the contract
            txRes = await c.guardianPause();
            await txRes.wait();

            // Case: contract is paused
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(c, err);

            // Case: contract is not paused
            txRes = await c.guardianUnpause();
            await txRes.wait();
            await expect(cUser.bid({ value: bid + fee })).to.not.be.reverted;
        });

        it("Should emit a `BidPlaced` event upon successfully placing a bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("81", 18);
            const event = "BidPlaced";

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            await expect(cUser.bid({ value: bid + fee }))
                .to.emit(cUser, event)
                .withArgs(addr, bid);
        });

        it("Should not allow an account without an ID NFT to bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const fee = await cDev.getFnFeeAdj(bidSel);

            const bid = parseUnits("19", 18);
            const err = auctionErr("NO_ID");

            // Start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // Has no ID NFT
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should not allow an account that is suspended to bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const reason = "test-reason";
            const err = auctionErr("SUSPENDED");
            const bid = parseUnits("22", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            txRes = await t.poi.contract.suspendAccount(addr, reason);
            await txRes.wait();

            // Suspended user places bid
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.revertedWithCustomError(cUser, err);
        });

        it("Should not allow an account with an expired account type property to bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const userType = PROOF_OF_ID_ATTRS.USER_TYPE;

            const addr = t.accountAddresses[0];
            const args = t.poi.defaultPOIArgs(addr);
            const exp = args.expiries[userType.id];

            const err = auctionErr("ATTRIBUTE_EXPIRED");
            const bid = parseUnits("22", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueIdentity(args);

            // Start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // Advance time to point where the ID NFT has expired
            await time.increase(exp);

            // Should not be able to place a bid with an expired ID.
            await expect(cUser.bid({ value: bid + fee }))
                .to.be.revertedWithCustomError(cUser, err)
                .withArgs(userType.name, exp);
        });

        it("Should not allow an account of the wrong account type to bid", async function () {
            // Setup
            const t = await loadFixture(setup);

            // Deploy auction for institutional users only
            const nftArgs: NFTAuctionArgs = {
                ...t.auctionArgs,
                config: {
                    ...t.auctionArgs.config,
                    kind: AuctionID.INSTITUTION,
                },
            };

            const institution = await deployNFTAuction(nftArgs, t.association);
            const cDev = institution.connect(t.developer);

            const cUser = institution.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];

            const args = t.poi.defaultPOIArgs(addr);
            args.userType = UserType.RETAIL;

            const err = auctionErr("USER_TYPE");
            const bid = parseUnits("90", 18);

            const fee = await cDev.getFnFeeAdj(bidSel);

            // Approve the new auction to transfer the NFT on behalf of the dev
            let txRes = await t.nft
                .connect(t.developer)
                .approve(await institution.getAddress(), nftArgs.config.nftID);
            await txRes.wait();

            // Issue the ID NFT (retail)
            await t.poi.issueIdentity(args);

            // Start auction
            txRes = await cDev.startAuction();
            await txRes.wait();

            await expect(cUser.bid({ value: bid + fee }))
                .to.revertedWithCustomError(cUser, err)
                .withArgs(UserType.RETAIL, UserType.INSTITUTION);
        });
    });

    /* Ending an Auction
    ======================================== */
    describe("Ending an Auction", function () {
        it("Should revert if the auction has not started", async function () {
            const t = await loadFixture(setup);

            const c = t.auction;
            const err = auctionErr("NOT_STARTED");

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the contract is paused", async function () {
            // Setup
            const t = await loadFixture(setup);
            const c = t.auction;
            const cDev = t.auction.connect(t.developer);

            const len = t.auctionArgs.config.length;

            const err = guardianErr("PAUSED");

            // Start the auction
            let txRes = await cDev.startAuction();
            txRes.wait();

            // Advance time to the end of the auction
            await time.increase(len);

            // State check
            const isPaused = await c.guardianPaused();
            expect(isPaused).to.be.false;

            // Pause the contract
            txRes = await c.guardianPause();
            await txRes.wait();

            // Case: contract is paused
            await expect(cDev.endAuction()).to.be.revertedWithCustomError(
                c,
                err
            );

            // Case: contract is not paused
            txRes = await c.guardianUnpause();
            await txRes.wait();
            await expect(cDev.endAuction()).to.not.be.reverted;
        });

        it("Should revert if called before the auction length has been met", async function () {
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);

            const err = auctionErr("ACTIVE");

            const txRes = await c.startAuction();
            txRes.wait();

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the auction is already finished", async function () {
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);
            const len = t.auctionArgs.config.length;
            const err = auctionErr("FINISHED");

            let txRes = await c.startAuction();
            txRes.wait();

            await time.increase(len);

            txRes = await c.endAuction();
            await txRes.wait();

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should transfer the prize NFT to the winner", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("22", 18);

            const len = t.auctionArgs.config.length;

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // User bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // Advance the time to the end of the auction
            await time.increase(len);

            const balBefore = await t.nft.balanceOf(addr);
            expect(balBefore).to.equal(0);

            txRes = await cUser.endAuction();
            await txRes.wait();

            const balAfter = await t.nft.balanceOf(addr);
            expect(balAfter).to.equal(1);
        });

        it("Should transfer the contract balance to the owner", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("22", 18);

            const len = t.auctionArgs.config.length;

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // User bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // Advance the time to the end of the auction.
            await time.increase(len);

            const balBefore = await getH1Balance(t.developerAddress);

            const contractBal = await getH1Balance(t.auctionAddress);
            expect(contractBal).to.equal(bid);

            txRes = await cUser.endAuction();
            await txRes.wait();

            const balAfter = await getH1Balance(t.developerAddress);
            const expected = balBefore + contractBal;

            expect(balAfter).to.equal(expected);
        });

        it("Should emit an `NFTSent` event when the NFT is transferred to the winner", async function () {
            // Setup
            const t = await loadFixture(setup);

            const cDev = t.auction.connect(t.developer);
            const cUser = t.auction.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const bid = parseUnits("22", 18);

            const len = t.auctionArgs.config.length;
            const event = "NFTSent";

            const fee = await cDev.getFnFeeAdj(bidSel);

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // User bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // Advance the time to the end of the auction.
            await time.increase(len);

            // test
            expect(cUser.endAuction).to.emit(cUser, event).withArgs(addr, bid);
        });
    });

    /* Account Eligibility
    ======================================== */
    describe("Account Eligibility", function () {
        it("Should return false if the account does not have an ID NFT", async function () {
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);
            const addr = t.accountAddresses[0];

            const txRes = await c.startAuction();
            await txRes.wait();

            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is suspended", async function () {
            // Setup
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);
            const addr = t.accountAddresses[0];
            const reason = "test-reason";

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // Suspend the user's account
            txRes = await t.poi.contract.suspendAccount(addr, reason);
            await txRes.wait();

            // test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is not of the requisite user type", async function () {
            // Setup
            const t = await loadFixture(setup);
            const addr = t.accountAddresses[0];
            const args = t.poi.defaultPOIArgs(addr);
            args.userType = UserType.RETAIL;

            // Deploy auction for institutional users only
            const nftArgs: NFTAuctionArgs = {
                ...t.auctionArgs,
                config: {
                    ...t.auctionArgs.config,
                    kind: AuctionID.INSTITUTION,
                },
            };

            const institution = await deployNFTAuction(nftArgs, t.association);
            await t.poi.issueIdentity(args);

            // Approve the new contract to transfer the NFT on behalf of the dev.
            let txRes = await t.nft
                .connect(t.developer)
                .approve(await institution.getAddress(), nftArgs.config.nftID);
            await txRes.wait();

            // Start auction
            txRes = await institution.connect(t.developer).startAuction();
            await txRes.wait();

            // Test
            const isEligible = await institution.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is has an expired user type attribute", async function () {
            // Setup
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);

            const addr = t.accountAddresses[0];
            const args = t.poi.defaultPOIArgs(addr);
            const exp = args.expiries[PROOF_OF_ID_ATTRS.USER_TYPE.id];

            await t.poi.issueIdentity(args);

            // Start auction
            const txRes = await c.startAuction();
            await txRes.wait();

            // Advance time to a point where the ID NFT has expired
            await time.increase(exp);

            // Test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return true if the account is eligible", async function () {
            // Setup
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);
            const addr = t.accountAddresses[0];

            await t.poi.issueDefaultIdentity(addr);

            // Start auction
            const txRes = await c.startAuction();
            await txRes.wait();

            // Test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.true;
        });
    });

    /* Misc
    ======================================== */
    describe("Misc", function () {
        it("Should correctly get the in progress and finished state", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);
            const len = t.auctionArgs.config.length;

            // Start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // Tests
            let inProgress = await c.inProgress();
            expect(inProgress).to.be.true;

            let hasFinished = await c.hasFinished();
            expect(hasFinished).to.be.false;

            await time.increase(len);

            txRes = await c.endAuction();
            await txRes.wait();

            inProgress = await c.inProgress();
            expect(inProgress).to.be.false;

            hasFinished = await c.hasFinished();
            expect(hasFinished).to.be.true;
        });

        it("Should correctly get the finish time", async function () {
            const t = await loadFixture(setup);

            const c = t.auction.connect(t.developer);

            const len = t.auctionArgs.config.length;

            const txRes = await c.startAuction();
            const txRec = await txRes.wait();

            const ts = await tsFromTxRec(txRec);

            const finishTime = await c.finishTime();
            const expected = BigInt(ts) + len;

            expect(finishTime).to.equal(expected);
        });
    });
});
