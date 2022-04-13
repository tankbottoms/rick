// import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

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
  });

  console.log('Deployed at:', Storage.address);
};

export default func;
