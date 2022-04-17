import { DeployFunction } from 'hardhat-deploy/types';
import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';
import { execSync } from 'child_process';

const func: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const base64URI = readFileSync(resolve(__dirname, '../out.base64')).toString();
  const metadata = JSON.parse(
    Buffer.from(base64URI.replace('data:application/json;base64,', ''), 'base64').toString(),
  );
  const iframeURL = metadata.animation_url as string;
  writeFileSync(
    resolve(__dirname, '../display.html'),
    `<iframe src="${iframeURL}" width="100%" height="100%" frameborder="0"></iframe>`,
  );
  // execSync(`open -a "Google Chrome" ${resolve(__dirname, '../display.html')}`);
};

export default func;
