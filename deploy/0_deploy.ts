// import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import rickRoll from '../buffer/rickRoll';
import rickRoll256 from '../buffer/rickRoll32Bytes';
import { execSync } from 'child_process';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  // console.log(rickRoll);
  // const uint256ArrayBuffer: string[] = [];
  // for (let i = 0; i < rickRoll.length; i += 32) {
  //   let hex = '';
  //   for (let b = 0; b < 32; b++) {
  //     const temp = (rickRoll[i + b] || 0).toString(16).padStart(2, '0');
  //     hex = temp + hex;
  //   }
  //   uint256ArrayBuffer.push(`0x${hex}`);
  // }
  // console.log(uint256ArrayBuffer);
  // (await import('fs')).default.writeFileSync('./buffer256.json', JSON.stringify(uint256ArrayBuffer));
  const chainId = await getChainId();
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const arrayBuffer = rickRoll256.slice(0).map((num) => BigNumber.from(num).toHexString());

  const baseDeployArgs = {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: chainId === '1',
  };

  const RickRoll = await deploy('RickRoll', {
    ...baseDeployArgs,
    args: [BigNumber.from(arrayBuffer.length), BigNumber.from(rickRoll.length)],
    gasLimit: BigNumber.from('10000000'),
  });

  console.log('Deployed at:', RickRoll.address);

  const contract = new ethers.Contract(
    RickRoll.address,
    RickRoll.abi,
    (await ethers.getSigners())[0],
  );

  const chunkSize = 100;
  for (
    let i = (await contract.bufferLength()).toNumber();
    i <= arrayBuffer.length;
    i = (await contract.bufferLength()).toNumber()
  ) {
    const from = i;
    const to = Math.min(i + chunkSize, arrayBuffer.length);
    const slice = arrayBuffer.slice(from, to);
    if (!slice.length) break;
    const txn = await contract.append(slice, {
      gasLimit: BigNumber.from('25000000'),
    });
    console.log(`Transacting ${from} - ${to} (${txn.hash}) ...`);
    await txn.wait();
  }

  console.log('Deployed at:', RickRoll.address);

  console.log('getting rickroll...');
  const str = await contract.getRickRoll();

  console.log(str);
};

export default func;
