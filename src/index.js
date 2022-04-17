const fs = require('fs');
const path = require('path');
const serve = require('./serve');
const boot = require('./boot');
const call = require('./call');
const compile = require('./compile');
const deploy = require('./deploy');

// const StorageSOURCE = path.join(__dirname, '..', 'contracts', 'Storage.sol');
const SOURCE = path.join(__dirname, '..', 'contracts', 'Token.sol');

async function main() {
  const { vm, pk } = await boot();

  async function handler() {
    // const { abi: storageAbi, bytecode: storageBytecode } = compile(StorageSOURCE);
    const { abi, bytecode } = compile(SOURCE);
    // const storageAddress = await deploy(vm, pk, storageBytecode);
    const address = await deploy(vm, pk, bytecode);
    // const storageResult =
    // await call(vm, storageAddress, storageAbi, 'example');
    const result = await call(vm, address, abi, 'tokenUri', '0x00');
    console.log(result);
    return result;
  }

  const { notify } = await serve(handler);

  fs.watch(path.dirname(SOURCE), notify);
  console.log('Watching', path.dirname(SOURCE));
  console.log('Serving  http://localhost:9901/');
}

module.exports = main;
