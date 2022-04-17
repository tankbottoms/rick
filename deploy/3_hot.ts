import { DeployFunction } from 'hardhat-deploy/types';
import main from '../src';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  await main();
  await new Promise((r) => {});
};

export default func;
