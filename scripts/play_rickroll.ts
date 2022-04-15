import { ethers, artifacts, default as hardhat } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { existsSync, readFileSync, promises as fs } from 'fs';
import { resolve } from 'path';
import { BigNumber, Contract, utils } from 'ethers';
import { execSync } from 'child_process';
import RickRoll from '../artifacts/contracts/RickRoll.sol/RickRoll.json';

async function main() {
  const contract = new ethers.Contract(
    '0x9ec46D9ff2fCf4509Bd32DA2Dc4069c12f20B234',
    RickRoll.abi,
    (await ethers.getSigners())[0],
  );

  const str = (await contract.getRickRoll()) as string;
  console.log(str);
  execSync(`/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome "${str}"`);
}

/* We recommend this pattern to be able to use async/await everywhere
  and properly handle errors. */
main()
  .then(() => process.exit(0))
  .catch(async (error: Error) => {
    console.error(error.message?.slice(0, 150));
    await fs.writeFile(resolve(__dirname, './error.json'), JSON.stringify(error, null, '  '));
    process.exit(1);
  });
