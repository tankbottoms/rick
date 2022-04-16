import { BigNumber } from 'ethers';
import { default as hre, ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

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

  const SToken = await deploy('SToken', {
    ...baseDeployArgs,
    args: [(await hre.deployments.get('SStorage')).address],
  });

  console.log('Deployed at:', SToken.address);

  /************************************************************************************/
  
  const contract = new ethers.Contract(SToken.address, SToken.abi, (await ethers.getSigners())[0]);

  /************************************************************************************/
  
  /*
    * bring the hot-svg-loader here
    * add svg UniSwap color background to project for a full color 
    * rotating sentence is the chorus of the song
    * load half dozen of the merkaba svgs into image storage contract
    * added roles to the storage contract to allow for the creation of new assets
    * 

  */

  console.log('getting asset...');
  const base64URI = await contract.tokenUri(0);
  console.log(base64URI);
  writeFileSync(resolve(__dirname, '../out.base64'), base64URI);
  console.log('Token Done!');
};

export default func;
