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

const StorageSOURCE = path.join(__dirname, '..', 'contracts', 'Storage.sol');
const SOURCE = path.join(__dirname, '..', 'contracts', 'Token.sol');

const NULL_ADDRESS = Address.fromString('0x0000000000000000000000000000000000000000');

async function main() {
  const { vm, pk } = await boot();

  async function handler() {
    const { abi: storageAbi, bytecode: storageBytecode } = compile(StorageSOURCE);
    const { abi, bytecode } = compile(SOURCE);

    const storageAddress =
      '0x' +
      ((await deploy(vm, pk, storageBytecode, storageAbi)) || NULL_ADDRESS)
        .toBuffer()
        .toString('hex');

    try {
      await tx(vm, pk, storageAddress, storageAbi, 'createAsset', '0x1000');

      const buffer = readFileSync(
        resolve(__dirname, `../buffer/${process.env.FILE_PREPEND || 'dev-'}rickRoll.mp3`),
      );
      const arrayBuffer = Array.from(buffer);
      const uint256ArrayBuffer: string[] = [];
      for (let i = 0; i < arrayBuffer.length; i += 32) {
        let hex = '';
        for (let b = 0; b < 32; b++) {
          const temp = (arrayBuffer[i + b] || 0).toString(16).padStart(2, '0');
          hex = temp + hex;
        }
        uint256ArrayBuffer.push(`0x${hex}`);
      }

      await tx(vm, pk, storageAddress, storageAbi, 'createAsset', '0x1000');
      await tx(vm, pk, storageAddress, storageAbi, 'appendAssetBuffer', '0x00', uint256ArrayBuffer);

      const address =
        '0x' +
        ((await deploy(vm, pk, bytecode, abi, storageAddress)) || NULL_ADDRESS)
          .toBuffer()
          .toString('hex');

      const result = await tx(vm, pk, address, abi, 'example');
      const returnString = result.execResult.returnValue.toString().trim().slice(3);
      const index = returnString.indexOf('data:');

      let str = returnString.slice(index).replace('data:application/json;base64,', '');
      const metadata = JSON.parse(Buffer.from(str, 'base64').toString());
      const animation_url = metadata.animation_url;
      console.log("reloading...");

      return `<iframe src="${animation_url}" width="100%" height="100%" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>`;
    } catch (error) {
      console.log(error);
    }
  }

  const { notify } = await serve(handler);

  fs.watch(path.dirname(SOURCE), notify);
  console.log('Watching', path.dirname(SOURCE));
  console.log('Serving  http://localhost:9901/');
}

export default main;