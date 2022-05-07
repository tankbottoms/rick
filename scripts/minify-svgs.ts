import fs from 'fs';
import { resolve } from 'path';

function main() {
  const dir = fs.readdirSync(resolve(__dirname, '../buffer/svgs'));

  for (const file of dir) {
    if (file) {
      const fileContent = fs
        .readFileSync(resolve(__dirname, `../buffer/svgs/${file}`), 'utf8')
        .replace(/[\s\n]+/g, ' ')
        .replace(/[:]\s+/g, ':')
        .replace(/[;]\s+/g, ';')
        .replace(/[>]\s+[<]/g, '><')
        .replace(/\s+\/[>]/g, '/>')
        .replace(/\s*{\s*/g, '{')
        .replace(/\s*}\s*/g, '}')
        .replace(/[,]\s+/g, ',')
        .replace(/[<]style[>]\s+/g, '<style>');
      fs.writeFileSync(resolve(__dirname, `../buffer/minified-svgs/${file}`), fileContent);
    }
  }
}

main();

export default main;
