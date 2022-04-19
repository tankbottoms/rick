import { promises as fs } from 'fs';
import path from 'path';

const project_name = ``;
const project_symbol = ``;
const project_description = ``;
const project_image_gif = `ipfs://`;
const project_external_url = `https://`;
const project_seller_fee_basis_points = 5000;
const project_fee_recipient = `0x`;

export const project_config = {
  tokenName: project_name,
  tokenSymbol: project_symbol,
  baseURI: project_base_uri,
  maxTokens: project_max_tokens,
  startSale: project_start_sale,
};

export const opensea_storefront = {
  name: project_name,
  description: project_description,
  image: project_image_gif,
  external_link: project_external_url,
  seller_fee_basis_points: project_seller_fee_basis_points,
  fee_recipient: project_fee_recipient,
};

false && console.log(project_config);

(async () => {
  console.log('writing opensea.json...');
  await fs.writeFile(
    path.join(__dirname, './opensea.json'),
    JSON.stringify(
      {
        name: project_name,
        description: project_description,
        image: project_image_gif,
        external_link: project_external_url,
        seller_fee_basis_points: project_seller_fee_basis_points,
        fee_recipient: project_fee_recipient,
        discord: 'https://discord.gg/',
        twitter: 'https://twitter.com/',
      },
      null,
      '  ',
    ),
  );
})();
