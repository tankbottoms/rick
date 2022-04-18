import { Address } from 'ethereumjs-util';
import { Transaction } from '@ethereumjs/tx';
import Web3 from 'web3';
import VM from '@ethereumjs/vm';

async function deploy(vm: VM, pk, bytecode, abi: any, ...args: any[]) {
  const web3 = new Web3();
  const address = Address.fromPrivateKey(pk);
  const account = await vm.stateManager.getAccount(address);
  try {
    const contract = new web3.eth.Contract(abi);
    const data = contract.deploy({ data: bytecode, arguments: args }).encodeABI();

    const tx = Transaction.fromTxData({
      value: 0,
      gasLimit: 200_000_000_000,
      gasPrice: 1,
      data: data,
      nonce: account.nonce,
    }).sign(pk);

    const deploymentResult = await vm.runTx({ tx });

    if (deploymentResult.execResult.exceptionError) {
      throw deploymentResult.execResult.exceptionError;
    }

    return deploymentResult.createdAddress;
  } catch (e: any) {
    console.log(e);
  }
}

export default deploy;
