import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import uuid4 from 'uuid4';
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

  const baseDeployArgs = {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: chainId === '1',
    gasLimit: BigNumber.from('25000000'),
  };

  const SStorage = await deploy('SStorage', {
    ...baseDeployArgs,
    args: [],
  });

  console.log('Deployed at:', SStorage.address);
  
  /************************************************************************************/
  const contract = new ethers.Contract(
    SStorage.address,
    SStorage.abi,
    (await ethers.getSigners())[0],
  );

  const assetKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);
  const assetId = 0;

  const assetCreateTxn: TransactionResponse = await contract.createAsset(
    BigNumber.from(assetId),
    assetKey,
    uint256ArrayBuffer
  );
  
  console.log(`Created Asset (id = ${assetId})`);
  console.log(`Asset Key: ${assetKey}`);
  console.log('Set to storage complete!');
};

export default func;
