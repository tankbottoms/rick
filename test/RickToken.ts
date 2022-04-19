import { BigNumber, Contract, ContractFactory } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync, readdirSync } from 'fs';
import uuid4 from 'uuid4';
import { TransactionResponse } from '@ethersproject/abstract-provider';
import 'colors';
import { bufferTo32ArrayBuffer, bufferToArrayBuffer } from '../utils/array-buffer';
import '../scripts/minify-svgs';



import { expect } from 'chai';
import fs from 'fs';
import * as path from 'path';

import { chunkAsset } from '../utils/helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

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
        await expect(token.connect(alice).setSaleActive(true)).ok;
        await expect(token.connect(robert).setSaleActive(false)).revertedWith('Ownable: caller is not the owner')
    });

    it("Test claim", async function () {
        await expect(token.connect(alice).setSaleActive(false)).ok;
        await expect(token.connect(robert).claim(1)).reverted;

        await expect(token.connect(alice).setSaleActive(true)).ok;
        await expect(token.connect(robert).claim(100)).reverted;
        await expect(token.connect(candace).claim(1)).ok;

        const tokensMinted = await token.connect(alice).tokensMinted();
        expect(tokensMinted.toString()).eq('1');
    });
});

// let tx: TransactionResponse = await token.connect(candace).claim(1);
// console.log(tx)