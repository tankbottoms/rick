import { BigNumber } from 'ethers';
import { default as hre } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const chainId = await getChainId();
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const baseDeployArgs = {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: chainId === '1',
    gasLimit: BigNumber.from('25000000'),
  };

  const Token = await deploy('Token', {
    ...baseDeployArgs,
    args: [(await hre.deployments.get('Storage')).address],
  });

  console.log('Deployed at:', Token.address);

  /*
   * bring the hot-svg-loader here
   * add svg UniSwap color background to project for a full color
   * rotating sentence is the chorus of the song
   * load half dozen of the merkaba svgs into image storage contract
   * added roles to the storage contract to allow for the creation of new assets
   */
};

export default func;
