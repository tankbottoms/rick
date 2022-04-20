import { artifacts, ethers } from 'hardhat';
import { TextEncoder } from 'util';
import pako from 'pako';
import fs from 'fs';
import path from 'path';

async function main() {
  const Factory = await ethers.getContractFactory('TestGZip');
  const TestGZip = await Factory.connect((await ethers.getSigners())[0]).deploy();
  console.log('\n\nDeployed at', TestGZip.address);
  console.log('');

  const text = ``;
  const input = new Uint8Array(new TextEncoder().encode(text));
  const compressed = pako.deflateRaw(input, { level: 9 });

  console.log('');
  console.log('input     : ', text.length, 'bytes');
  console.log('');
  console.log('original  : ', `0x${buf2hex(input.buffer)}`.slice(2).length / 2, 'bytes');
  console.log('');
  console.log('compressed: ', `0x${buf2hex(compressed.buffer)}`.slice(2).length / 2, 'bytes');
  console.log('');

  await TestGZip.deployed();
  const result = await TestGZip.puff(compressed, input.length);
  const decompressed = result[1];

  console.log('decompress: ', `${decompressed}`.slice(2).length / 2, 'bytes');
  console.log('');
  console.log('');
}

main();

function buf2hex(buffer) {
  return Array.prototype.map.call(new Uint8Array(buffer), (x) => ('00' + x.toString(16)).slice(-2)).join('');
}
