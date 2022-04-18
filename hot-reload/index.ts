import fs from 'fs';
import path from 'path';
import serve from './serve';
import boot from './boot';
import tx from './tx';
import call from './call';
import compile from './compile';
import deploy from './deploy';
import { Address } from 'ethereumjs-util';
import { BigNumber } from 'ethers';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { bufferTo32ArrayBuffer, bufferToArrayBuffer } from '../utils/array-buffer';
import uuid4 from 'uuid4';
import 'colors';

const StorageSOURCE = path.join(__dirname, '..', 'contracts', 'Storage.sol');
const SOURCE = path.join(__dirname, '..', 'contracts', 'Token.sol');

const NULL_ADDRESS = Address.fromString('0x0000000000000000000000000000000000000000');

async function main() {
  const { vm, pk, address: walletAddress } = await boot();

  async function handler() {
    const { abi: storageAbi, bytecode: storageBytecode } = compile(StorageSOURCE);
    const { abi, bytecode } = compile(SOURCE);

    const storageAddress = '0x' + ((await deploy(vm, pk, storageBytecode, storageAbi)) || NULL_ADDRESS).toBuffer().toString('hex');

    try {
      const ASSETS = [
        `buffer/dev-rickRoll.mp3`,
        `buffer/merkaba/1.svg`,
        `buffer/merkaba/2.svg`,
        `buffer/merkaba/3.svg`,
        `buffer/merkaba/4.svg`,
        `buffer/merkaba/5.svg`,
        `buffer/merkaba/6.svg`,
        `buffer/merkaba/7.svg`,
        `buffer/merkaba/8.svg`,
      ];

      let assetId = 0;
      for (const ASSET of ASSETS) {
        const CHUNK_SIZE = Math.floor((1024 * 24) / 32); // 24KB
        const buffer = readFileSync(resolve(__dirname, `..`, ASSET));
        const arrayBuffer = bufferToArrayBuffer(buffer);
        const arrayBuffer32 = bufferTo32ArrayBuffer(buffer);
        // const contract = new ethers.Contract(Storage.address, Storage.abi, (await ethers.getSigners())[0]);

        for (let i = 0; i < arrayBuffer32.length; i += CHUNK_SIZE) {
          const sliceKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);

          const from = `${i * 32}`.padStart(6, '0');
          const to = `${Math.min(arrayBuffer.length, (i + CHUNK_SIZE) * 32)}`.padStart(6, '0');
          console.log(`uploading ${ASSET} from ${from} to ${to} [of total ${arrayBuffer.length} bytes]`.yellow);

          const args: any[] = [BigNumber.from(assetId), sliceKey, arrayBuffer32.slice(i, i + CHUNK_SIZE)];
          if (i === 0) args.push(arrayBuffer.length);

          await tx(vm, pk, storageAddress, storageAbi, i === 0 ? 'createAsset' : 'appendAssetContent', ...args);
        }

        assetId++;
      }

      // await tx(vm, pk, storageAddress, storageAbi, 'createAsset', '0x1000');

      // const buffer = readFileSync(resolve(__dirname, `../buffer/${process.env.FILE_PREPEND || 'dev-'}rickRoll.mp3`));
      // const arrayBuffer = Array.from(buffer);
      // const uint256ArrayBuffer: string[] = [];
      // for (let i = 0; i < arrayBuffer.length; i += 32) {
      //   let hex = '';
      //   for (let b = 0; b < 32; b++) {
      //     const temp = (arrayBuffer[i + b] || 0).toString(16).padStart(2, '0');
      //     hex = temp + hex;
      //   }
      //   uint256ArrayBuffer.push(`0x${hex}`);
      // }

      // await tx(vm, pk, storageAddress, storageAbi, 'createAsset', '0x1000');
      // await tx(vm, pk, storageAddress, storageAbi, 'appendAssetBuffer', '0x00', uint256ArrayBuffer);

      const address = '0x' + ((await deploy(vm, pk, bytecode, abi, storageAddress)) || NULL_ADDRESS).toBuffer().toString('hex'); // Deploy Token

      const tokenId = `0x${Math.floor(Math.random() * 100)}`;

      const result = await tx(vm, pk, address, abi, 'tokenUri', tokenId);
      const returnString = result.execResult.returnValue.toString().trim().slice(3);
      const index = returnString.indexOf('data:');

      let str = returnString.slice(index).replace('data:application/json;base64,', '');
      
      const metadata = JSON.parse(Buffer.from(str, 'base64').toString());
      const animation_url = metadata.animation_url;
      console.log('reloading...');

      return `<iframe tokenId="${Number(
        tokenId,
      )}" address="${walletAddress}" src="${animation_url}" width="100%" height="100%" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>`;
    } catch (error: any) {
      console.log(error);
      return error.message;
    }
  }

  const { notify } = await serve(handler);

  fs.watch(path.dirname(SOURCE), notify);
  console.log('Watching', path.dirname(SOURCE));
  console.log('Serving  http://localhost:9901/');
}

export default main;
