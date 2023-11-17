// SPDX-License-Identifier: GPL-3.0
import { ethers } from "hardhat";
import { expect } from "chai";
import { beforeEach } from "mocha";
import { Contract, BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


let nftInternalCollectionRevealer_mockedVRF: any;

const NAME: string = "Mash NFT";
const DESCRIPTION: string = "Mash NFT";
const MAX_SUPPLY: any = 6;
const NUM_WORDS: any = 6;
const REVEAL_METADATA: any = [
    '{"trait1": "value1"}',
    '{"trait2": "value2"}',
    '{"trait3": "value3"}',
    '{"trait4": "value4"}',
    '{"trait5": "value5"}',
    '{"trait6": "value6"}'
];
const UNREVEALED_METADATA: any = '{"generic_trait": "generic_value"}';
const SUBSCRIPTION_ID = 7204;

describe("NFTInternalCollectionRevealer_mockedVRF", () => {
    let OWNER: any;
    let collector1: any;
    let collector2: any;
    let owner_account: SignerWithAddress;
    let collector_account1: SignerWithAddress;
    let collector_account2: SignerWithAddress;
    let DEPLOYER: Contract;
    let COLLECTOR1_WALLET: Contract;
    let MASH_COLLECTION_MEDIA_METADATA: any;
    
    beforeEach(async () => {
        const NFTInternalCollectionRevealer_mockedVRF = await ethers.getContractFactory("NFTInternalCollectionRevealer_mockedVRF");

        [owner_account, collector_account1, collector_account2] = await ethers.getSigners();

        OWNER = await owner_account.getAddress();
        collector1 = await collector_account1.getAddress();
        collector2 = await collector_account1.getAddress();

        nftInternalCollectionRevealer_mockedVRF = await NFTInternalCollectionRevealer_mockedVRF.connect(owner_account).deploy(
            NAME, 
            DESCRIPTION, 
            OWNER
        );

        await nftInternalCollectionRevealer_mockedVRF.connect(owner_account).confirm_vrf_intialized();
        await nftInternalCollectionRevealer_mockedVRF.connect(owner_account).start_reveal();

        await nftInternalCollectionRevealer_mockedVRF.mint(collector1);
        await nftInternalCollectionRevealer_mockedVRF.mint(collector1);
        await nftInternalCollectionRevealer_mockedVRF.mint(collector1);
        await nftInternalCollectionRevealer_mockedVRF.mint(collector2);
        await nftInternalCollectionRevealer_mockedVRF.mint(collector2);
        await nftInternalCollectionRevealer_mockedVRF.mint(collector2);
    });

    it('Is able to mint new NFTs to the collection to a collector', async function () {
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(1)).to.equal(collector1);
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(2)).to.equal(collector1);
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(3)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(4)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(5)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer_mockedVRF.ownerOf(6)).to.equal(collector2);
    });

    it('Is able to transfer NFTs to another wallet when called by owner', async function () {
        const tokenId = 1;

        expect(await nftInternalCollectionRevealer_mockedVRF.tokenURI(tokenId)).to.equal(UNREVEALED_METADATA);

        await nftInternalCollectionRevealer_mockedVRF.connect(owner_account).start_reveal();
        await nftInternalCollectionRevealer_mockedVRF.connect(collector_account1).reveal(tokenId, 0);

        expect(await nftInternalCollectionRevealer_mockedVRF.tokenURI(tokenId)).to.not.equal(UNREVEALED_METADATA);
        console.log(await nftInternalCollectionRevealer_mockedVRF.tokenURI(tokenId));
    });
});