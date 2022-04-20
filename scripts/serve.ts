import fs from 'fs';
import path from 'path';
import http from 'http';
import EventEmitter from 'events';
import * as hre from 'hardhat';
import { artifacts, ethers } from 'hardhat';
import { writeFileSync } from 'fs';
import { resolve } from 'path';
import { uploadFiles } from '../deploy/0_deploy';
import { TransactionResponse } from '@ethersproject/abstract-provider';

const SOURCE = path.join(__dirname, '..', 'contracts', 'Token.sol');
const webpage = (content) => `
<html>
<title>Hot Chain SVG</title>
${content}
<script>
const sse = new EventSource('/changes');
sse.addEventListener('change', () => window.location.reload());
</script>
</html>
`;

async function update() {
  try {
    await new Promise((r) => fs.rm(path.resolve(__dirname, '../deployments/hardhat'), { recursive: true }, () => r(true)));
  } catch (e) {}

  await hre.deployments.delete('Token');
  await hre.run('compile');
  const signer = (await ethers.getSigners())[0];

  const StorageArtifact = await artifacts.readArtifact('Storage');
  const StorageFactory = await ethers.getContractFactory('Storage');
  const Storage = await StorageFactory.connect(signer).deploy();

  await uploadFiles(Storage.address, StorageArtifact.abi, signer);

  const TokenArtifact = await artifacts.readArtifact('Token');
  const TokenFactory = await ethers.getContractFactory('Token');
  const Token = await TokenFactory.connect(signer).deploy(Storage.address);

  const tokenContract = new ethers.Contract(Token.address, TokenArtifact.abi, signer);

  await (await tokenContract.setSaleActive(true)).wait();
  const txn: TransactionResponse = await tokenContract.claim(1, { value: ethers.utils.parseEther('0.04') });
  await txn.wait();
  console.log('claimed\nGetting tokenUri...');
  const base64URI: string = await tokenContract.dataUri(0);
  writeFileSync(resolve(__dirname, '../out.base64'), base64URI);
  console.log('ready!');

  const base64 = base64URI.split(',')[1];
  const json = JSON.parse(Buffer.from(base64, 'base64').toString());
  return json;
}

async function main() {
  let promise = update();
  const { notify } = await serve(async () => {
    try {
      const json = await promise;
      const audio = json.animation_url.split('#')[1];
      const html = Buffer.from(json.animation_url.split('#')[0].replace('data:text/html;base64,', ''), 'base64').toString();
      return `${html}<script>location.href="/#${audio}"</script>`;
    } catch (error: any) {
      return `<pre>${JSON.stringify(error, null, '  ')}</pre>`;
    }
  });
  fs.watch(path.dirname(SOURCE), () => {
    promise = update();
    notify();
  });
  notify();

  await promise;

  console.log('Watching', path.dirname(SOURCE));
  console.log('Serving  http://localhost:9901/');
  await new Promise(() => null);
}
main();

async function serve(handler) {
  const events = new EventEmitter();

  function requestListener(req, res) {
    if (req.url === '/changes') {
      res.setHeader('Content-Type', 'text/event-stream');
      res.writeHead(200);
      const sendEvent = () => res.write('event: change\ndata:\n\n');
      events.on('change', sendEvent);
      req.on('close', () => events.off('change', sendEvent));
      return;
    }

    if (req.url === '/') {
      res.writeHead(200);
      handler().then(
        (content) => res.end(webpage(content)),
        (error) => res.end(webpage(`<pre>${error.message}</pre>`)),
      );
      return;
    }

    res.writeHead(404);
    res.end('Not found: ' + req.url);
  }
  const server = http.createServer(requestListener);
  await new Promise((resolve) => server.listen(9901, () => resolve(true)));

  return {
    notify: () => events.emit('change'),
  };
}

process.on('uncaughtException', (err) => console.log(err.message));
process.on('unhandledRejection', (err: any) => console.log(err.message));
