import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { TransactionRequest, TransactionResponse } from '@ethersproject/abstract-provider';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const buffer = readFileSync(resolve(__dirname, '../buffer/rickRoll.mp3'));
  const arrayBuffer = Array.from(buffer);
  const bytes = arrayBuffer.length;
  console.log('Audio Size (KB):', bytes / 1024);
  const uint256ArrayBuffer: string[] = [];
  for (let i = 0; i < arrayBuffer.length; i += 32) {
    let hex = '';
    for (let b = 0; b < 32; b++) {
      const temp = (arrayBuffer[i + b] || 0).toString(16).padStart(2, '0');
      hex = temp + hex;
    }
    uint256ArrayBuffer.push(`0x${hex}`);
  }
  /************************************************************************************/
  const chainId = await getChainId();
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const arrayBuffer256 = uint256ArrayBuffer
    .slice(0)
    .map((num) => BigNumber.from(num).toHexString());

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

  console.log('Deployed at:', Storage.address);
  /************************************************************************************/
  const contract = new ethers.Contract(
    Storage.address,
    Storage.abi,
    (await ethers.getSigners())[0],
  );

  const assetCreateTxn: TransactionResponse = await contract.createAsset(
    BigNumber.from(arrayBuffer.length),
  );
  const assetCreateTxnReceipt = await assetCreateTxn.wait();
  const assetId = assetCreateTxnReceipt?.logs[0].data;
  console.log(`Created Asset (ID = ${assetId})`);

  const chunkSize = 100;
  for (
    let i = await contract.progress(assetId);
    i <= arrayBuffer256.length;
    i = await contract.progress(assetId)
  ) {
    const from = i;
    const to = Math.min(i + chunkSize, arrayBuffer256.length);
    const slice = arrayBuffer256.slice(from, to);
    if (!slice.length) break;
    const txn = await contract.appendAssetBuffer(assetId, slice, {
      gasLimit: BigNumber.from('25000000'),
    });
    console.log(`Transacting ${from} - ${to} (${txn.hash}) ...`);
    await txn.wait();
  }
  /************************************************************************************/
  // console.log('getting asset...');
  // const assetBytes = await contract.getAssetBytes(assetId);
  // console.log(`\n${assetBytes}\n`);
  console.log('Storage Done!');
};

export default func;
