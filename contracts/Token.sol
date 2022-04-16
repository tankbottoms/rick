// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import {Base64} from './libraries/Base64.sol';
import {IToken} from './interfaces/IToken.sol';
import {IStorage} from './interfaces/IStorage.sol';

contract Token is IToken, ERC721, Ownable {
    uint256 private _totalSupply;
    IStorage public assets;

    constructor(IStorage _assets) ERC721('Peace DAO Movement', 'PEACE') {
        assets = _assets;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function tokenUri(uint256 tokenId) public view override returns (string memory) {
        string
            memory html = '<img src="https://cloudflare-ipfs.com/ipfs/QmdmPHWQBzV24GvbwCszm2AnWetBENeBP2UStuETsyAp1C" width="400" /><br><svg onclick="(()=>{playing?{song1.pause();song2.pause();var playing = false}:{song1.play();song2.play();var playing = true}})()" width="32px" height="32px" viewBox="0 0 32 32"><circle id="play" cx="16" cy="16" r="16" fill="#f0f0f0" /><polygon id="stop" points="10,10 22,10, 22,22 10,22" fill="" /><polygon points="10,7 10,25 25,15" fill="" /></svg><audio src="" id="song1" volume="0.1" style="display: none;"></audio><audio src="" id="song2" volume="0.1" style="display: none;"></audio><script>const songs = [song1, song2];const tracks = location.hash.slice(1).split("#");const betterQuality = ["", "https://cloudflare-ipfs.com/ipfs/QmWmmmrQB3iFXHPNStyL7GvgZcifGz3JrzcFbSLQzyevjn"];for(let i =0;i<songs.length;i++) songs[i].src = (navigator.onLine && betterQuality[i]) || tracks[i];</script>';

        return
            string(
                abi.encodePacked(
                    '{"name": "Ocarina #1", "description": "A unique piece of music represented entirely on-chain in the MIDI format with inspiration from the musical themes and motifs of video games.", "image": "https://cloudflare-ipfs.com/ipfs/QmdmPHWQBzV24GvbwCszm2AnWetBENeBP2UStuETsyAp1C", "animation_url": "',
                    'data:text/html;base64,',
                    Base64.encode(bytes(html)),
                    '#',
                    '#',
                    getAudioAssetBase64(0),
                    '", "external_url": "http://beatfoundry.xyz", "attributes": [{"trait_type": "Chord Progression", "value": "2"}, {"trait_type": "First Melody", "value": "2"}, {"trait_type": "Second Melody", "value": "1"}, {"trait_type": "Third Melody", "value": "3"}, {"trait_type": "Drums", "value": "3"}], "composer": "Shaw Avery @ShawAverySongs"}'
                )
            );
    }

    function getAudioAssetBase64(uint16 _assetId) public view override returns (string memory) {
        return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(assets.getAssetBytes(_assetId))));
    }

    // function mint(address _to, uint256 _tokenId) public onlyOwner {
    // }

    // function generateString(

    // function generateColorNumber(string memory name, uint256 tokenId) internal pure returns (uint256) {

    // function generateNum(

    // function generateNumUint(

    // function genDefs(uint256 tokenId) internal view returns (string memory) {

    // function genMiddle(uint256 tokenId) internal pure returns (string memory) {

    // function genSquares(uint256 tokenId) internal view returns (string memory) {

    // function genEnd(uint256 tokenId) internal view returns (string memory) {

    // function generateDistortion(uint256 tokenId) public view returns (string memory) {

    // function getFrequency(uint256 tokenId) internal view returns (uint256) {

    // function tokenURI(uint256 tokenId) public view override returns (string memory) {

    // // Keeping track of supply and displaying it.
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenSupply;
    // constructor() ERC721('Peace DAO Movement', 'PEACE') {
    //     _tokenSupply = new Counters.Counter(0);
    // }
    // /**
    //  * @notice This shows the randomness of block 14156329 which included the mint of the 1000th original Distortion piece.
    //  *
    //  */
    // string public constant HASH_OF_BLOCK = '0x8f6ddc7b27b8492318761d4361e2e24eedb4d56602f4f575560071e873f5a4f9';
    // /**
    //  * @notice Returns the total supply of tokens airdropped.
    //  *
    //  */
    // function totalSupply() public view returns (uint256 supply) {
    //     return _tokenSupply.current();
    // }
    // /**
    //  * @notice Once this shows true, it cannot be reversed, making the airdrop function uncallable.
    //  *
    //  */
    // bool public airdropPermanentlyDisabled;
    // /**
    //  * @notice This function will be called to disable airdrops permanently once all the tokens have been airdropped.
    //  *
    //  */
    // function disableAirdrop() public onlyOwner {
    //     require(!airdropPermanentlyDisabled, 'Once the airdrop function is disabled it cannot be re-enabled.');
    //     airdropPermanentlyDisabled = true;
    // }
    // /**
    //  * @notice The airdrop function which will be permanently disabled once all tokens have been airdropped.
    //  *
    //  */
    // function airdrop(address[] memory _to, uint256[][] memory _tokenIds) public onlyOwner {
    //     require(!airdropPermanentlyDisabled, 'Once the airdrop is disabled, the function can never be called again.');
    //     for (uint256 i = 0; i < _to.length; i++) {
    //         for (uint256 z = 0; z < _tokenIds[i].length; z++) {
    //             _safeMint(_to[i], _tokenIds[i][z]);
    //             _tokenSupply.increment();
    //         }
    //     }
    // }
    // /**
    //  * @notice The mint function which will be permanently disabled once all tokens have been minted.
    //  *
    //  */
    // function mint(address _to, uint256 _tokenId) public onlyOwner {
    //     require(!airdropPermanentlyDisabled, 'Once the airdrop is disabled, the function can never be called again.');
    //     _safeMint(_to, _tokenId);
    //     _tokenSupply.increment();
    // }
    // /*
    // ░██████╗░███████╗███╗░░██╗███████╗██████╗░░█████╗░████████╗██╗██╗░░░██╗███████╗
    // ██╔════╝░██╔════╝████╗░██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝
    // ██║░░██╗░█████╗░░██╔██╗██║█████╗░░██████╔╝███████║░░░██║░░░██║╚██╗░██╔╝█████╗░░
    // ██║░░╚██╗██╔══╝░░██║╚████║██╔══╝░░██╔══██╗██╔══██║░░░██║░░░██║░╚████╔╝░██╔══╝░░
    // ╚██████╔╝███████╗██║░╚███║███████╗██║░░██║██║░░██║░░░██║░░░██║░░╚██╔╝░░███████╗
    // ░╚═════╝░╚══════╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝
    // Everything to do with the on-chain generation of the Distortion pieces.
    // */
    // string[] private colorNames = ['White', 'Red', 'Green', 'Blue', 'Gold', 'Rose', 'Purple'];
    // string[] private left = [
    //     'rgb(140,140,140)',
    //     'rgb(255, 26, 26)',
    //     'rgb(92, 214, 92)',
    //     'rgb(26, 140, 255)',
    //     'rgb(255, 215, 0)',
    //     'rgb(255, 128, 128)',
    //     'rgb(192, 50, 227)'
    // ];
    // string[] private right = [
    //     'rgb(52,52,52)',
    //     'rgb(230, 0, 0)',
    //     'rgb(51, 204, 51)',
    //     'rgb(0, 115, 230)',
    //     'rgb(204, 173, 0)',
    //     'rgb(255, 102, 102)',
    //     'rgb(167, 40, 199)'
    // ];
    // string[] private middleLeft = [
    //     'rgb(57,57,57)',
    //     'rgb(179, 0, 0)',
    //     'rgb(41, 163, 41)',
    //     'rgb(0, 89, 179)',
    //     'rgb(153, 130, 0)',
    //     'rgb(255, 77, 77)',
    //     'rgb(127, 32, 150)'
    // ];
    // string[] private middleRight = [
    //     'rgb(20,20,20)',
    //     'rgb(128, 0, 0)',
    //     'rgb(31, 122, 31)',
    //     'rgb(0, 64, 128)',
    //     'rgb(179, 152, 0)',
    //     'rgb(255, 51, 51)',
    //     'rgb(98, 19, 117)'
    // ];
    // string[] private frequencies = ['', '0', '00'];
    // function generateString(
    //     string memory name,
    //     uint256 tokenId,
    //     string[] memory array
    // ) internal pure returns (string memory) {
    //     uint256 rand = uint256(keccak256(abi.encodePacked(name, toString(tokenId)))) % array.length;
    //     string memory output = string(abi.encodePacked(array[rand % array.length]));
    //     return output;
    // }
    // function generateColorNumber(string memory name, uint256 tokenId) internal pure returns (uint256) {
    //     uint256 output;
    //     uint256 rand = uint256(keccak256(abi.encodePacked(name, toString(tokenId)))) % 100;
    //     if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(''))) {
    //         output = 0; //unrevealed
    //     } else {
    //         if (rand <= 15) {
    //             output = 1; //Red with 15% rarity.
    //         } else if (rand > 15 && rand <= 30) {
    //             output = 2; //Green with 15% rarity.
    //         } else if (rand > 30 && rand <= 45) {
    //             output = 3; //Blue with 15% rarity.
    //         } else if (rand > 45 && rand <= 75) {
    //             output = 0; //Black with 30% rarity.
    //         } else if (rand > 75 && rand <= 80) {
    //             output = 4; //Gold with 5% rarity.
    //         } else if (rand > 80 && rand <= 90) {
    //             output = 5; //Rose with 10% rarity.
    //         } else if (rand > 90) {
    //             output = 6; //Purple with 10% rarity.
    //         }
    //     }
    //     return output;
    // }
    // function generateNum(
    //     string memory name,
    //     uint256 tokenId,
    //     string memory genVar,
    //     uint256 low,
    //     uint256 high
    // ) internal pure returns (string memory) {
    //     uint256 difference = high - low;
    //     uint256 randomnumber = (uint256(keccak256(abi.encodePacked(genVar, tokenId, name))) % difference) + 1;
    //     randomnumber = randomnumber + low;
    //     return toString(randomnumber);
    // }
    // function generateNumUint(
    //     string memory name,
    //     uint256 tokenId,
    //     string memory genVar,
    //     uint256 low,
    //     uint256 high
    // ) internal pure returns (uint256) {
    //     uint256 difference = high - low;
    //     uint256 randomnumber = (uint256(keccak256(abi.encodePacked(genVar, tokenId, name))) % difference) + 1;
    //     randomnumber = randomnumber + low;
    //     return randomnumber;
    // }
    // function genDefs(uint256 tokenId) internal view returns (string memory) {
    //     string memory output;
    //     string memory xFrequency = generateString('xF', tokenId, frequencies);
    //     string memory yFrequency = generateString('yF', tokenId, frequencies);
    //     string memory scale = generateNum('scale', tokenId, HASH_OF_BLOCK, 10, 40);
    //     if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(''))) {
    //         xFrequency = '';
    //         yFrequency = '';
    //         scale = '30';
    //     }
    //     output = string(
    //         abi.encodePacked(
    //             '<defs><filter id="squares" x="-30%" y="-30%" width="160%" height="160%"> <feTurbulence type="turbulence" baseFrequency="',
    //             '0.',
    //             xFrequency,
    //             '5 0.',
    //             yFrequency,
    //             '5',
    //             '" numOctaves="10" seed="" result="turbulence"> <animate attributeName="seed" dur="0.3s" repeatCount="indefinite" calcMode="discrete" values="1;2;3;4;5;6;7;8;9;1"/> </feTurbulence> <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="',
    //             scale,
    //             '" xChannelSelector="R" yChannelSelector="G" /> </filter> </defs>'
    //         )
    //     );
    //     return output;
    // }
    // function genMiddle(uint256 tokenId) internal pure returns (string memory) {
    //     string memory translate = toString(divide(generateNumUint('scale', tokenId, HASH_OF_BLOCK, 10, 40), 5, 0));
    //     string[5] memory p;
    //     if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(''))) {
    //         translate = '6';
    //     }
    //     p[
    //         0
    //     ] = '<style alt="surround"> #1 { stroke-dasharray: 50,50,150 } .cls-2 { fill: rgba(140,140,140, 1);}.cls-3 {fill: rgba(140,140,140, 0.3);}</style><g style="filter: url(#squares);" opacity="100%" id="1"> <g transform="translate(-';
    //     p[1] = translate;
    //     p[2] = ', -';
    //     p[3] = translate;
    //     p[4] = ')" >';
    //     string memory output = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4]));
    //     return output;
    // }
    // function genSquares(uint256 tokenId) internal view returns (string memory) {
    //     string memory output1;
    //     string memory output2;
    //     uint256 ringCount = generateNumUint('ringCount', tokenId, HASH_OF_BLOCK, 5, 15);
    //     string[2] memory xywh;
    //     uint256 ringScaling = divide(25, ringCount, 0);
    //     if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(''))) {
    //         ringCount = 5;
    //         ringScaling = 5;
    //     }
    //     for (uint256 i = 0; i < ringCount; i++) {
    //         xywh[0] = toString(ringScaling * i + 5);
    //         xywh[1] = toString(100 - (ringScaling * i + 5) * 2);
    //         output1 = string(
    //             abi.encodePacked(
    //                 '<g style="animation: glitch 1.',
    //                 toString(i),
    //                 's infinite;"> <rect x="',
    //                 xywh[0],
    //                 '%" y="',
    //                 xywh[0],
    //                 '%" width="',
    //                 xywh[1],
    //                 '%" height="',
    //                 xywh[1],
    //                 '%" fill="none" stroke="',
    //                 left[generateColorNumber('color', tokenId)],
    //                 '" id="1" /> </g>'
    //             )
    //         );
    //         output2 = string(abi.encodePacked(output1, output2));
    //     }
    //     return output2;
    // }
    // function genEnd(uint256 tokenId) internal view returns (string memory) {
    //     uint256 colorNum = generateColorNumber('color', tokenId);
    //     string[13] memory p;
    //     p[
    //         0
    //     ] = '</g> </g><g style="animation: glitch 0.5s infinite;filter: url(#squares);"> <g transform="scale(0.40) translate(750, 750)" style="opacity:40%"> <path fill="';
    //     p[1] = right[colorNum];
    //     p[
    //         2
    //     ] = '" d="M500,0C223.86,0,0,223.86,0,500s223.86,500,500,500,500-223.86,500-500S776.14,0,500,0ZM878,500a376.44,376.44,0,0,1-82.55,235.81L560,500.34V126.71C740.27,155.46,878,311.64,878,500ZM440,873.29a375.83,375.83,0,0,1-147.13-57L440,669.15ZM560,670,706.59,816.63A375.73,375.73,0,0,1,560,873.29ZM440,126.71V499.45L204.13,735.32A376.48,376.48,0,0,1,122,500C122,311.64,259.73,155.46,440,126.71Z"/>';
    //     p[3] = '</g> </g> </svg>';
    //     string memory output = string(abi.encodePacked(p[0], p[1], p[2], p[3]));
    //     return output;
    // }
    // /**
    //  * @notice Generate the SVG of any Distortion piece, including token IDs that are out of bounds.
    //  *
    //  */
    // function generateDistortion(uint256 tokenId) public view returns (string memory) {
    //     string memory output;
    //     output = string(
    //         abi.encodePacked(
    //             '<svg width="750px" height="750px" viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="background-color: ',
    //             colorNames[generateColorNumber('color', tokenId)],
    //             ';"><style> @keyframes glitch { 0% {transform: translate(0px); opacity: 0.15;} 7% {transform: translate(2px); opacity: 0.65;} 45% {transform: translate(0px); opacity: 0.35;} 50% {transform: translate(-2px); opacity: 0.85;} 100% {transform: translate(0px); opacity: 0.25;} } </style> <defs> <filter id="background" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="linearRGB"> <feTurbulence type="fractalNoise" baseFrequency="10" numOctaves="4" seed="1" stitchTiles="stitch" x="0%" y="0%" width="100%" height="100%" result="turbulence"> <animate attributeName="seed" dur="1s" repeatCount="indefinite" calcMode="discrete" values="1;2;3;4;5;6;7;8;9;10" /> </feTurbulence> <feSpecularLighting surfaceScale="10" specularExponent="10" lighting-color="#fff" width="100%" height="100%"> <animate attributeName="surfaceScale" dur="1s" repeatCount="indefinite" calcMode="discrete" values="10;11;12;13;14;15;14;13;12;11" /> <feDistantLight elevation="100"/> </feSpecularLighting> </filter> </defs> <g opacity="10%"> <rect width="700" height="700" fill="hsl(23, 0%, 100%)" filter="url(#background)"></rect></g>',
    //             genDefs(tokenId),
    //             genMiddle(tokenId),
    //             genSquares(tokenId),
    //             "</g></g><foreignobject class='node' x='46' y='22' width='100' height='100'><audio src='https://s3.amazonaws.com/freecodecamp/simonSound1.mp3' autoplay='true' loop='true'></audio></foreignobject><g>",
    //             genEnd(tokenId)
    //         )
    //     );
    //     return output;
    // }
    // function getFrequency(uint256 tokenId) internal view returns (uint256) {
    //     uint256[2] memory xy;
    //     string memory y = generateString('yF', tokenId, frequencies);
    //     string memory x = generateString('xF', tokenId, frequencies);
    //     if (keccak256(bytes(x)) == keccak256(bytes('0'))) {
    //         xy[0] = 2;
    //     } else if (keccak256(bytes(x)) == keccak256(bytes('00'))) {
    //         xy[0] = 1;
    //     } else {
    //         xy[0] = 3;
    //     }
    //     if (keccak256(bytes(y)) == keccak256(bytes('0'))) {
    //         xy[1] = 2;
    //     } else if (keccak256(bytes(y)) == keccak256(bytes('00'))) {
    //         xy[1] = 1;
    //     } else {
    //         xy[1] = 3;
    //     }
    //     return xy[0] * xy[1];
    // }
    // /**
    //  * @notice
    //  *
    //  */
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "Token doesn't exist. Try using the generateDistortion function to generate non-existant pieces.");
    //     string memory ringCount = generateNum('ringCount', tokenId, HASH_OF_BLOCK, 5, 15);
    //     string memory scale = generateNum('scale', tokenId, HASH_OF_BLOCK, 10, 40);
    //     uint256 freq = getFrequency(tokenId);
    //     string memory json = Base64.encode(
    //         bytes(
    //             string(
    //                 abi.encodePacked(
    //                     '{"name": "Distortion #',
    //                     toString(tokenId),
    //                     '","attributes": [ { "trait_type": "Color", "value": "',
    //                     colorNames[generateColorNumber('color', tokenId)],
    //                     '" }, { "trait_type": "Distortion Scale", "value": ',
    //                     scale,
    //                     ' }, { "trait_type": "Rings", "value": ',
    //                     ringCount,
    //                     ' }, { "trait_type": "Frequency Multiple", "value": ',
    //                     toString(freq),
    //                     ' }]',
    //                     ', "description": "Distortion is a fully hand-typed 100% on-chain art collection.", "image": "data:image/svg+xml;base64,',
    //                     Base64.encode(bytes(string(abi.encodePacked(generateDistortion(tokenId))))),
    //                     '"}'
    //                 )
    //             )
    //         )
    //     );
    //     string memory output = string(abi.encodePacked('data:application/json;base64,', json));
    //     return output;
    // }
    // /**
    //  * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    //  */
    // function toString(uint256 value) internal pure returns (string memory) {
    //     // Inspired by OraclizeAPI's implementation - MIT licence
    //     // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    //     if (value == 0) {
    //         return '0';
    //     }
    //     uint256 temp = value;
    //     uint256 digits;
    //     while (temp != 0) {
    //         digits++;
    //         temp /= 10;
    //     }
    //     bytes memory buffer = new bytes(digits);
    //     while (value != 0) {
    //         digits -= 1;
    //         buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
    //         value /= 10;
    //     }
    //     return string(buffer);
    // }
    // function divide(
    //     uint256 a,
    //     uint256 b,
    //     uint256 precision
    // ) internal pure returns (uint256) {
    //     return (a * (10**precision)) / b;
    // }
}
