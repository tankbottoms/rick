import fs from 'fs';
import { program } from 'commander';
import { parseBalanceMap } from './utils/parse-balance-map';

program
  .version('0.0.1')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a map of account addresses to string balances'
  )
  .requiredOption(
    '-o, --output <path>',
    'output json file'
  );

program.parse(process.argv);
const options = program.opts();

const json = JSON.parse(fs.readFileSync(options.input, { encoding: 'utf8' }));
if (typeof json !== 'object') throw new Error('Invalid JSON');
fs.writeFileSync(options.output, JSON.stringify(parseBalanceMap(json)));