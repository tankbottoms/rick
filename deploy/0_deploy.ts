import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import uuid4 from 'uuid4';
import { TransactionRequest, TransactionResponse } from '@ethersproject/abstract-provider';

function chunkArray(arr, size) {
    let result: any[] = [];

    for (let i = 0; i < arr.length; i += size) {
        let chunk: any = arr.slice(i, i + size);
        result.push(chunk);
    }

    return result;
}

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const buffer = readFileSync(resolve(__dirname, '../buffer/rick-roll.mp3'));
//   console.log(buffer.toString('hex'))
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
// console.log(uint256ArrayBuffer[0], uint256ArrayBuffer[1], uint256ArrayBuffer[uint256ArrayBuffer.length - 2], uint256ArrayBuffer[uint256ArrayBuffer.length - 1])
  const slices = chunkArray(uint256ArrayBuffer, 1024 * 24 / 32);

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
  const contract = new ethers.Contract(SStorage.address, SStorage.abi, (await ethers.getSigners())[0]);

  const assetKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);
  const assetId = 0;

  const assetCreateTxn: TransactionResponse = await contract.createAsset(BigNumber.from(assetId), assetKey, slices[0]);
  console.log(`Created Asset (ID = ${assetId})`);

//   let size = await contract.getAssetSize(BigNumber.from(assetId));
//   console.log(size);

//   const head = await contract.getContentForKey(assetKey);
  


  for (let i = 1; i < slices.length; i++) {
    const assetSliceKey = '0x' + Buffer.from(uuid4(), 'utf-8').toString('hex').slice(-64);
    const assetAppendTxn: TransactionResponse = await contract.appendAssetContent(BigNumber.from(assetId), assetSliceKey, slices[i]);
  }

//   const tail = await contract.getContentForKey(assetKey);


//   size = await contract.getAssetSize(BigNumber.from(assetId));
//   console.log(size);

//   console.log('bytes', bytes, uint256ArrayBuffer.length, slices.length, slices[slices.length - 1][slices[slices.length - 1].length - 1])


    // const keys = await contract.getAssetKeysForId(assetId);
    // console.log(keys[6])
    // const tail = await contract.getContentForKey(keys[6]);
    // console.log(tail[tail.length - 1], uint256ArrayBuffer[uint256ArrayBuffer.length - 1])

    // const fullcontent = await contract.getAssetContentForId(BigNumber.from(assetId));
    // console.log(fullcontent)


  console.log('Storage Done!');
};

export default func;
