import { Address } from 'ethereumjs-util';
import { Transaction } from '@ethereumjs/tx';
import VM from '@ethereumjs/vm';
import { Interface } from '@ethersproject/abi';

async function tx(vm: VM, pk, contractAddress: string, abi: any, name: string, ...args: any[]) {
  const iface = new Interface(abi);
  const data = iface.encodeFunctionData(name, args);

  const address = Address.fromPrivateKey(pk);
  const account = await vm.stateManager.getAccount(address);
  const tx = Transaction.fromTxData({
    value: 0,
    to: contractAddress,
    gasLimit: 200_000_000_000,
    gasPrice: 1,
    data: Buffer.from(data.slice(2), 'hex'),
    nonce: account.nonce,
  }).sign(pk);

  const result = await vm.runTx({ tx });

  if (result.execResult.exceptionError) {
    throw result.execResult.exceptionError;
  }

  return result;
}

export default tx;
