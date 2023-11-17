// SPDX-License-Identifier: GPL-3.0
import { ethers } from "hardhat";
import { expect } from "chai";
import { beforeEach } from "mocha";
import { Contract, BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


let nftInternalCollectionRevealer: any;

const NAME: string = "TEST COLLECTION 1";
const DESCRIPTION: string = "TEST1";
const MINT_PRICE: any = 0;
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
const UNREAVEALED_METADATA: any = '{"generic_trait": "generic_value"}';

describe("NFTInternalCollectionRevealer", () => {
    let owner: any;
    let collector1: any;
    let collector2: any;
    let owner_account: SignerWithAddress;
    let collector_account1: SignerWithAddress;
    let collector_account2: SignerWithAddress;
    let DEPLOYER: Contract;
    let COLLECTOR1_WALLET: Contract;
    let MASH_COLLECTION_MEDIA_METADATA: any;
    
    beforeEach(async () => {
        const NFTInternalCollectionRevealer = await ethers.getContractFactory("NFTInternalCollectionRevealer");

        [owner_account, collector_account1, collector_account2] = await ethers.getSigners();

        owner = await owner_account.getAddress();
        collector1 = await collector_account1.getAddress();
        collector2 = await collector_account1.getAddress();

        nftInternalCollectionRevealer = await NFTInternalCollectionRevealer.connect(owner_account).deploy(
            NAME, 
            DESCRIPTION,
            owner, 
            MINT_PRICE, 
            REVEAL_METADATA, 
            UNREAVEALED_METADATA,
            MAX_SUPPLY,
            ethers.getAddress("0xd9145cce52d386f254917e481eb44e9943f39138")
        );

        await nftInternalCollectionRevealer.connect(owner_account).confirm_vrf_intialized();
        await nftInternalCollectionRevealer.connect(owner_account).start_reveal();

        await nftInternalCollectionRevealer.mint(collector1);
        await nftInternalCollectionRevealer.mint(collector1);
        await nftInternalCollectionRevealer.mint(collector1);
        await nftInternalCollectionRevealer.mint(collector2);
        await nftInternalCollectionRevealer.mint(collector2);
        await nftInternalCollectionRevealer.mint(collector2);
    });

    it('Is able to mint new NFTs to the collection to a collector', async function () {
        expect(await nftInternalCollectionRevealer.ownerOf(1)).to.equal(collector1);
        expect(await nftInternalCollectionRevealer.ownerOf(2)).to.equal(collector1);
        expect(await nftInternalCollectionRevealer.ownerOf(3)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer.ownerOf(4)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer.ownerOf(5)).to.equal(collector2);
        expect(await nftInternalCollectionRevealer.ownerOf(6)).to.equal(collector1);
    });
});