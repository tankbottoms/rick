import { BigNumber, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync, readdirSync } from 'fs';
import { resolve } from 'path';
import uuid4 from 'uuid4';
import { TransactionResponse } from '@ethersproject/abstract-provider';
import 'colors';
import { bufferTo32ArrayBuffer, bufferToArrayBuffer } from '../utils/array-buffer';
import '../scripts/minify-svgs';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import pako from 'pako';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const chainId = await getChainId();
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const baseDeployArgs = {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: chainId === '1',
    gasLimit: BigNumber.from('25000000'),
  };

  const Storage = await deploy('Storage', {
    ...baseDeployArgs,
    args: [],
  });

  console.log('Storage Deployed at:', Storage.address);

  await uploadFiles(Storage.address, Storage.abi, (await ethers.getSigners())[0]);
};

export default func;

export async function uploadFiles(address: string, abi: any, signer: SignerWithAddress) {
  const ASSETS = [
    `buffer/${process.env.FILE_PREPEND}rickRoll.mp3`,
    ...readdirSync(resolve(__dirname, '../buffer/minified-svgs'))
      .filter((filename) => filename.endsWith('.svg'))
      .sort((a, b) => Number(a.replace('.svg', '')) - Number(b.replace('.svg', '')))
      .map((filename) => `buffer/minified-svgs/${filename}`),
  ];

  let assetId = 0;
  let totalSavedBytes = 0;
  for (const ASSET of ASSETS) {
    const CHUNK_SIZE = Math.floor((1024 * 24) / 32); // 24KB
    let buffer = readFileSync(resolve(__dirname, `..`, ASSET));
    let arrayBuffer = bufferToArrayBuffer(buffer);
    let arrayBuffer32 = bufferTo32ArrayBuffer(buffer);
    if (ASSET.endsWith('.svg')) {
      const uncompressed = Uint8Array.from(buffer);
      arrayBuffer = pako.deflateRaw(uncompressed, { level: 9 });
      arrayBuffer32 = bufferTo32ArrayBuffer(Buffer.from(arrayBuffer));
      totalSavedBytes += buffer.length - arrayBuffer.length;
    }
    const contract = new ethers.Contract(address, abi, signer);

    for (let i = 0; i < arrayBuffer32.length; i += CHUNK_SIZE) {
      const sliceKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);

      const from = `${i * 32}`.padStart(6, '0');
      const to = `${Math.min(arrayBuffer.length, (i + CHUNK_SIZE) * 32)}`.padStart(6, '0');

      console.log(`uploading ${ASSET} from ${from} to ${to} [of total ${arrayBuffer.length} bytes]`.yellow);

      const args: any[] = [BigNumber.from(assetId), sliceKey, arrayBuffer32.slice(i, i + CHUNK_SIZE)];
      if (i === 0) args.push(arrayBuffer.length);

      const assetAppendTxn: TransactionResponse = await contract[i === 0 ? 'createAsset' : 'appendAssetContent'](...args);
      await assetAppendTxn.wait();
    }

    if (ASSET.endsWith('.svg')) {
      const setInflateSizeTxn: TransactionResponse = await contract.setAssetAttribute(assetId, '_inflatedSize', 2, [
        `0x${buffer.length.toString(16).padStart(64, '0')}`,
      ]);
      await setInflateSizeTxn.wait();
    }



    assetId++;
  }

  console.log(`SAVED`, totalSavedBytes, 'bytes');
}
