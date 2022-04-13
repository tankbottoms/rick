// import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import rickRoll from '../buffer/rickRoll';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const chainId = await getChainId();
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const baseDeployArgs = {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: chainId === '1',
  };

  const Storage = await deploy('Storage', {
    ...baseDeployArgs,
    args: [],
    gasLimit: BigNumber.from('600000'),
  });

  console.log('Deployed at:', Storage.address);

  const contract = new ethers.Contract(Storage.address, Storage.abi, (await ethers.getSigners())[0]);

  const chunkSize = 1000;
  for (let i = 0; i < rickRoll.length; i += chunkSize) {
    console.log(`Transacting ${i} - ${i + chunkSize} ...`);
    const txn = await contract.append(rickRoll.slice(i, i + chunkSize), {
      gasLimit: BigNumber.from('10000000'),
    });
    await txn.wait();
  }

  console.log('Deployed at:', Storage.address);
};

export default func;
