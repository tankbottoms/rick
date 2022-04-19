import { expect } from 'chai';
import fs from 'fs';
import * as path from 'path';
import { ethers } from 'hardhat';
import uuid4 from 'uuid4';
import { TransactionResponse } from '@ethersproject/abstract-provider';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import { chunkAsset } from '../utils/helpers';

enum AssetDataType {
    AUDIO_MP3,
    IMAGE_SVG,
    IMAGE_PNG
}

async function loadAssets(storage: any, signer: SignerWithAddress, assets: string[]) {
    let assetId = 0;

    for (const assetPath of assets) {
        const assetParts = chunkAsset(assetPath);

        let sliceKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);
        let tx: TransactionResponse = await storage.connect(signer).createAsset(assetId, sliceKey, assetParts.parts[0], assetParts.length, { gasLimit: 5_000_000 });
        await tx.wait();

        for (let i = 1; i < assetParts.parts.length; i++) {
            sliceKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);
            tx = await storage.connect(signer).appendAssetContent(assetId, sliceKey, assetParts.parts[i], { gasLimit: 5_000_000 });
            await tx.wait();
        }

        assetId++;
    }
}

describe("Rick Token tests", function () {
    this.timeout(1_200_000);

    let storage: any;
    let token: any;
    let alice: any;
    let robert: any;
    let candace: any;

    this.beforeAll(async () => {
        [alice, robert, candace] = await ethers.getSigners();

        const Storage = await ethers.getContractFactory('Storage');
        storage = await Storage.connect(alice).deploy();
        await storage.deployed();

        const Token = await ethers.getContractFactory('Token');
        token = await Token.connect(alice).deploy(storage.address);
        await token.deployed();

        const audio = [path.join('buffer', 'rickRoll.mp3')];
        const svg = fs.readdirSync(path.resolve(__dirname, '..', 'buffer', 'minified-svgs'))
            .filter((filename) => filename.endsWith('.svg'))
            .sort((a, b) => Number(a.slice(0, -4)) - Number(b.slice(0, -4)))
            .map((filename) => path.join('buffer', 'minified-svgs', filename));

        await loadAssets(storage, alice, [...audio, ...svg]);
    });

    it("Test setSaleActive", async () => {
        await expect(token.connect(alice).setSaleActive(true)).to.be.ok;
        await expect(token.connect(robert).setSaleActive(false)).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it("Test claim", async () => {
        await expect(token.connect(alice).setSaleActive(false)).ok;
        await expect(token.connect(robert).claim(1)).revertedWith('PUBLIC_SALE_NOT_ACTIVE()');

        await expect(token.connect(alice).setSaleActive(true)).ok;
        await expect(token.connect(robert).claim(100)).to.be.revertedWith('INCORRECT_TOKEN_AMOUNT()');

        let tokensMinted = await token.connect(alice).tokensMinted();
        expect(tokensMinted.toString()).eq('0');

        await expect(token.connect(candace).claim(1, { value: ethers.utils.parseEther('0.0005') })).to.be.revertedWith('INCORRECT_TOKEN_AMOUNT');
        await expect(token.connect(candace).claim(1, { value: ethers.utils.parseEther('0.04') })).ok;
        await expect(token.connect(candace).claim(1, { value: ethers.utils.parseEther('0.05') })).ok;

        tokensMinted = await token.connect(alice).tokensMinted();
        expect(tokensMinted.toString()).eq('2');
    });

    it("Test airdrop", async () => {
        await expect(token.connect(robert).airdrop([alice.address])).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(token.connect(alice).airdrop([robert.address])).ok;

        let tokensOwned = await token.connect(alice).balanceOf(alice.address);
        expect(tokensOwned.toString()).eq('0');

        tokensOwned = await token.connect(alice).balanceOf(robert.address);
        expect(tokensOwned.toString()).eq('1');

        tokensOwned = await token.connect(candace).balanceOf(candace.address);
        expect(tokensOwned.toString()).eq('2');

        let tokenOwner = await token.connect(candace).ownerOf(0);
        expect(tokenOwner.toString()).eq(candace.address);

        tokenOwner = await token.connect(candace).ownerOf(2);
        expect(tokenOwner.toString()).eq(robert.address);
    });

    it("Test getAssetBase64", async () => {
        const imageData = await token.connect(candace).getAssetBase64(1, AssetDataType.IMAGE_SVG);
        fs.writeFileSync(path.resolve(__dirname, 'imageData.out'), imageData);

        const audioData = await token.connect(candace).getAssetBase64(0, AssetDataType.AUDIO_MP3);
        fs.writeFileSync(path.resolve(__dirname, 'audioData.out'), audioData);
    });

    it("Test rollState & dataUri", async () => {
        await expect(token.connect(candace).rollState(1, { value: ethers.utils.parseEther('0.0005') })).to.be.revertedWith('INSUFFICIENT_FUNDS()');
        await expect(token.connect(candace).rollState(1, { value: ethers.utils.parseEther('0.005') })).ok;
        await expect(token.connect(candace).rollState(1, { value: ethers.utils.parseEther('0.005') })).to.be.revertedWith('ALREADY_ROLLED()');
        await expect(token.connect(candace).rollState(0, { value: ethers.utils.parseEther('0.005') })).to.be.ok;

        const token0Data = await token.connect(candace).dataUri(0);
        fs.writeFileSync(path.resolve(__dirname, 'token0Data.out'), token0Data);

        const token2Data = await token.connect(candace).dataUri(2);
        fs.writeFileSync(path.resolve(__dirname, 'token2Data.out'), token2Data);
    });

    it("Test whitelistClaim", async () => {
        console.log('whitelistClaim TESTS MISSING');
    });

    it("Test withdrawAll", async () => {
        console.log('withdrawAll TESTS MISSING');
    });
});

// let tx: TransactionResponse = await token.connect(candace).claim(1);
// console.log(tx)