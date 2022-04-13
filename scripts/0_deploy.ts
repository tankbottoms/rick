import { ethers, artifacts, default as hardhat } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { existsSync, readFileSync, promises as fs } from 'fs';
import { resolve } from 'path';
import { BigNumber, Contract, utils } from 'ethers';

/*
   network options are: localhost, mainnet, rinkeby, mumbai, matic
   npx hardhat run ./scripts/deploy.ts --network rinkeby    
*/

let resume = existsSync(resolve(__dirname, `${hardhat.network['name']}.json`))
  ? JSON.parse(readFileSync(resolve(__dirname, `${hardhat.network['name']}.json`)).toString())
  : {};

async function onEthereum() {
  if (
    hardhat.network['name'].toString() == 'rinkeby' ||
    hardhat.network['name'].toString() == 'mainnet'
  )
    return true;
  return false;
}

async function saveResume() {
  try {
    return await fs.writeFile(
      resolve(__dirname, `${hardhat.network['name']}.json`),
      JSON.stringify(resume, null, '  '),
    );
  } catch (e: any) {
    console.error(`Error, while saving ${hardhat.network['name']}.json file:${e.message}`);
  }
}

async function deployAndVerify(signer: SignerWithAddress, contractName: string, ...args) {
  console.log();
  const artifact = await artifacts.readArtifact(contractName);
  if (resume[contractName] && JSON.stringify(resume[contractName].args) === JSON.stringify(args)) {
    console.info(`Contract ${contractName} already deployed`);
    const contract = new ethers.Contract(resume[contractName].address, artifact.abi, signer);
    if (!resume[contractName].varified) await verify(contract);
    (contract as any)['abi'] = artifact.abi;
    return contract;
  }

  console.log(`Deploying contract ${contractName}`);
  const Factory = await ethers.getContractFactory(contractName);
  const contract = await Factory.connect(signer).deploy(...args);
  await contract.deployTransaction.wait(1);
  (contract as any)['abi'] = artifact.abi;
  console.log(
    `Deployed contract ${contractName} ${contract.address} ` +
      args.map((arg) => `"${arg}"`).join(' '),
  );

  resume[contractName] = {
    address: contract.address,
    owner: await signer.getAddress(),
    args: args,
    txnHash: contract.deployTransaction.hash,
    gasLimit: contract.deployTransaction.gasLimit.toString(),
    gasPrice: (contract.deployTransaction.gasPrice || BigNumber.from(0)).toString(),
    txnFee: utils.formatEther(
      contract.deployTransaction.gasLimit
        .mul(contract.deployTransaction.gasPrice || BigNumber.from(0))
        .toString(),
    ),
  };

  await saveResume();
  (await onEthereum()) && (await verify(contract));
  return contract;

  async function verify(contract: Contract) {
    try {
      await contract?.deployTransaction?.wait(5);
      console.info(`Verifying:${contractName}`);
      await hardhat.run('verify:verify', {
        address: contract.address,
        constructorArguments: args.filter((arg) => typeof arg.gasLimit === 'undefined'),
      });
      console.log(`Verified: ${contractName}`);
      resume[contractName].verified = true;
      await saveResume();
    } catch (error: any) {
      if (typeof error?.message === 'string') {
        if (error?.message?.match(/already\s+verified/i)) {
          console.log(`Already verified: ${contractName}`);
          resume[contractName].verified = true;
          await saveResume();
          return;
        }
      }
      console.error('Error:', error.message);
    }
  }
}

async function main() {
  const [signer, ..._] = await ethers.getSigners();
  (await onEthereum())
    ? console.log(`Ethereum contracts will be verified after deployment`)
    : console.log(`Deployment on Polygon, skipping Etherscan verification.`);
  const Storage = await deployAndVerify(signer, 'Storage');
  console.log('Waiting for contract verification to finish...');
  console.log('Done');
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
