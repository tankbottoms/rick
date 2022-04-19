// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './libraries/Base64.sol';
import './interfaces/IToken.sol';
import './interfaces/IStorage.sol';
import './enums/AssetDataType.sol';

error NOT_IN_FOUNDER_LIST();
error ALL_TOKENS_MINTED();
error EXCEEDS_TOKEN_SUPPLY();
error PUBLIC_SALE_NOT_ACTIVE();
error WHITELIST_SALE_NOT_ACTIVE();
error TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
error INCORRECT_TOKEN_AMOUNT();
error INSUFFICIENT_FUNDS();
error EXCEEDS_WALLET_ALLOWANCE();
error ADDRESS_NOT_IN_WHITELIST();
error NOT_READY_TO_ROLL();

contract Token is IToken, ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IStorage public assets;
    uint256 private _totalSupply;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant setupRick = 0.005 ether;
    uint256 public price = 0.04 ether;
    uint256 public whitelistPrice = 0.01 ether;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_ADDRESS = 15;
    uint256 public constant MAX_PER_ADDRESS_WHITELIST = 25;
    uint256 public constant MAX_PER_FOUNDER_ADDRESS = 50;
    bool public readyToRoll = false;
    bool public publicSaleActive = false;
    bool public whitelistSaleActive = true;
    uint256 public graphicId = 0;
    bytes32 public whitelistMerkleRoot;

    mapping(address => bool) public founderList;
    mapping(address => uint256) private _mintedPerAddress;
    mapping(address => uint256) private _whitelistMintedPerAddress;

    event RicksMinted(address sender, uint256 mintedCount, uint256 lastMintedTokenID);

    modifier isFounder() {
        if (!founderList[msg.sender]) {
            revert NOT_IN_FOUNDER_LIST();
        }
        _;
    }

    constructor(IStorage _assets) ERC721('Rick', 'RICK') {
        assets = _assets;
    }

    function _bulkMint(uint256 numTokens, address destination) private {
        if (tokensMinted() + numTokens > MAX_SUPPLY) {
            revert EXCEEDS_TOKEN_SUPPLY();
        }

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(destination, newItemId);
            _tokenIds.increment();
        }
        _mintedPerAddress[destination] += numTokens;
        emit RicksMinted(destination, numTokens, _tokenIds.current() - 1);
    }

    function claim(uint256 numTokens) public payable virtual override nonReentrant {
        if (!publicSaleActive) {
            revert PUBLIC_SALE_NOT_ACTIVE();
        }
        if (price * numTokens < msg.value) {
            revert INCORRECT_TOKEN_AMOUNT();
        }
        if (_mintedPerAddress[msg.sender] + numTokens > MAX_PER_ADDRESS) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if (numTokens > MAX_PER_TX) {
            revert TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
        }

        _bulkMint(numTokens, msg.sender);
    }

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof) public payable virtual override nonReentrant {
        if (!whitelistSaleActive) {
            revert WHITELIST_SALE_NOT_ACTIVE();
        }
        if (!MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert ADDRESS_NOT_IN_WHITELIST();
        }
        if (
            _whitelistMintedPerAddress[msg.sender] == MAX_PER_ADDRESS_WHITELIST ||
            _whitelistMintedPerAddress[msg.sender] + numTokens > MAX_PER_ADDRESS_WHITELIST
        ) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if (whitelistPrice * numTokens < msg.value) {
            revert INSUFFICIENT_FUNDS();
        }

        _bulkMint(numTokens, msg.sender);
    }

    function airdrop(address[] memory to) public override onlyOwner {
        if (tokensMinted() + to.length > MAX_SUPPLY) {
            revert EXCEEDS_TOKEN_SUPPLY();
        }

        for (uint256 i = 0; i < to.length; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(to[i], newItemId);
            _tokenIds.increment();
        }
    }

    function claimForFriend(uint256 numTokens, address walletAddress) public payable virtual override {
        if (!publicSaleActive) {
            revert PUBLIC_SALE_NOT_ACTIVE();
        }
        if (price * numTokens < msg.value) {
            revert INSUFFICIENT_FUNDS();
        }
        if (_mintedPerAddress[msg.sender] + numTokens > MAX_PER_ADDRESS) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if (numTokens > MAX_PER_TX) {
            revert TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
        }

        _bulkMint(numTokens, walletAddress);
    }

    function ownerClaim(uint256 numTokens) public override onlyOwner {
        _bulkMint(numTokens, msg.sender);
    }

    function founderClaim(uint256 numTokens) public override isFounder {
        if (_mintedPerAddress[msg.sender] + numTokens > MAX_PER_FOUNDER_ADDRESS) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }

        _bulkMint(numTokens, msg.sender);
    }

    /**
     * By default the NFT is a colorful NFT with a Merkaba design pattern.
     * However you can flip the NFT state to reveal a Click Me Button.
     * When the button is pressed, then the Rick SVG is revealed and music plays in a loop.
     * The Rick mode stays for 72 hours for normal users and 1 week for founders, afterwhich the state is flipped back.
     * Users must send the setupRick  to the contract to flip the state where the founders can just flip for gas.
     * Remove any links to any files externally from the contract, including the high-resolution Rick.
     **/
    function flipRickState(bool _flip) public payable override nonReentrant {
        if (!readyToRoll) {
            revert NOT_READY_TO_ROLL();
        }

        if (founderList[msg.sender]) {
            readyToRoll = true;
        } else {
            if (msg.value != setupRick) {
                revert INSUFFICIENT_FUNDS();
            }
            readyToRoll = true;
        }
    }

    function setMainSVG(uint256 _graphicId) public override {
        graphicId = _graphicId;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function tokenUri(uint256 tokenId) public view override returns (string memory) {
        return dataUri(tokenId);
    }

    function getAssetBase64(uint64 _assetId, AssetDataType _assetType) public view override returns (string memory) {
        string memory prefix = '';

        if (_assetType == AssetDataType.AUDIO_MP3) {
            prefix = 'data:audio/mp3;base64,';
        } else if (_assetType == AssetDataType.IMAGE_SVG) {
            prefix = 'data:image/svg+xml;base64,';
        } else if (_assetType == AssetDataType.IMAGE_PNG) {
            prefix = 'data:image/png;base64,';
        }

        return string(abi.encodePacked(prefix, Base64.encode(assets.getAssetContentForId(_assetId))));
    }

    function withdrawAll() public payable override onlyOwner {
        require(payable(msg.sender).send(address(this).balance), 'transfer failed');
    }

    function tokensMinted() public view override returns (uint256) {
        return _tokenIds.current() - 1;
    }

    function isSaleActive() public view override returns (bool) {
        return publicSaleActive;
    }

    function isWhitelistSaleActive() public view override returns (bool) {
        return whitelistSaleActive;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) public override onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setSaleActive(bool status) public override onlyOwner {
        publicSaleActive = status;
    }

    function setWhitelistSaleActive(bool status) public override onlyOwner {
        whitelistSaleActive = status;
    }

    function setFounderList(address[] calldata founderAddr) public override onlyOwner {
        for (uint256 i = 0; i < founderAddr.length; i++) {
            founderList[founderAddr[i]] = true;
        }
    }

    function dataUri(uint256 tokenId) public view override returns (string memory) {
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "RickRoll #',
                Strings.toString(tokenId),
                '", "description": "Fully on-chain, Rick Astley RickRoll MP3 SVG NFT", "audio": "',
                getAssetBase64(uint64(0), AssetDataType.AUDIO_MP3),
                '", "image": "',
                getAssetBase64(uint64(1), AssetDataType.IMAGE_SVG),
                '", "animation_url": "',
                _getHTMLBase64(tokenId),
                '#',
                getAssetBase64(uint64(0), AssetDataType.AUDIO_MP3),
                '#", "attributes":[{"trait_type":"RickRolled","value":"yes"}]}'
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _getHTMLBase64(uint256 tokenId) internal view returns (string memory) {
        string[18] memory merkaba;

        for (uint8 i = 0; i < 18; i++) {
            merkaba[i] = string(assets.getAssetContentForId(i + 1));
        }

        string
            memory html = unicode'<style type="text/css" media="screen">html,body{padding: 0;margin: 0;	font-size: 1em;	line-height: 1.2;font-family: "Simple Console", monospace;}pre {position: absolute;	margin:0;padding:0;	left:0;	top:0;width:1000px;height:2000px;color: white;opacity: 0.5;font-family: inherit;transform: scale(0.7);transform-origin:10px 10px;}</style><audio src="" id="song1" volume="0.1" style="display: none;" loop="true"></audio><audio src="" id="song2" volume="0.1" style="display: none;" loop="true"></audio><script>const songs = [song1, song2];const tracks = location.hash.slice(1).split("#");const betterQuality = ["", ""];for(let i =0;i<songs.length;i++) songs[i].src = (navigator.onLine && betterQuality[i]) || tracks[i];</script>';

        string[4] memory filters = [
            '',
            '173%22%20cy%3D%22129%22%20r%3D%22120px%22%20fill%3D%22%23',
            '353%22%20cy%3D%22157%22%20r%3D%22120px%22%20fill%3D%22%23',
            '237%22%20cy%3D%22314%22%20r%3D%22100px%22%20fill%3D%22%23'
        ];

        string[4] memory colors;

        bytes memory hexBytes = abi.encodePacked(Strings.toHexString(uint256(uint160(msg.sender))));
        for (uint8 i = 0; i < 4; i++) {
            for (uint8 j = 0; j < 3; j++) {
                filters[i] = string(abi.encodePacked(filters[i], hexBytes[i * 3 + (tokenId % 15) + 2 + j], hexBytes[i * 3 + (tokenId % 15) + 3 + j]));
                colors[i] = string(abi.encodePacked(colors[i], hexBytes[i * 3 + (tokenId % 15) + 2 + j], hexBytes[i * 3 + (tokenId % 15) + 3 + j]));
            }
        }

        string memory clickMeText = '';
        if (uint8((uint8(hexBytes[18]) + 1) * (tokenId + 1)) > 128) {
            clickMeText = '<g style="transform:translate(35px, 235px)"> <rect width="54px" height="17.3333px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"></rect><text x="8px" y="11.333px" font-family="\'Courier New\', monospace" font-size="8px" fill="white">Click me</text></g>';
        }

        string memory uniswap = string(
            abi.encodePacked(
                string(
                    abi.encodePacked(
                        '<svg width="500" height="500" viewBox="0 0 290 290"> <defs> <style> @import url("https://gateway.pinata.cloud/ipfs/QmRodGNTG8Jex8nQQwufuNi4Brb4Cqy16YBJ3CKqBYfQKP/DM_Mono.css"); </style> <filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Crect%20width%3D%22290px%22%20height%3D%22290px%22%20fill%3D%22%23',
                        filters[0],
                        '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p1" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Ccircle%20cx%3D%22',
                        filters[1],
                        '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p2" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%3Ccircle%20cx%3D%22',
                        filters[2],
                        '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p3" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%20%3Ccircle%20cx%3D%22',
                        filters[3]
                    )
                ),
                '%22%20style%3D%22animation%3A%20move-around%2010s%20linear%20infinite%22%2F%3E%20%3Cstyle%3E%40keyframes%20move-around%7B0%25%7Btransform%3A%20translate(0%2C%200)%3B%7D25%25%7Btransform%3A%20translate(-290px%2C%20-290px)%3B%7D50%25%7Btransform%3A%20translate(290px%2C%20-290px)%3B%7D75%25%7Btransform%3A%20translate(-290px%2C%20290px)%3B%7D100%25%7Btransform%3A%20translate(0%2C%200)%3B%7D%7D%3C%2Fstyle%3E%3C%2Fsvg%3E"> </feImage><feBlend mode="overlay" in="p0" in2="p1"></feBlend> <feBlend mode="exclusion" in2="p2"></feBlend> <feBlend mode="overlay" in2="p3" result="blendOut"></feBlend> <feGaussianBlur in="blendOut" stdDeviation="42"></feGaussianBlur> </filter> <clipPath id="corners"> <rect width="290" height="290" rx="42" ry="42"></rect> </clipPath> <path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V250 A28 28 0 0 1 250 278 H40 A28 28 0 0 1 12 250 V40 A28 28 0 0 1 40 12 z"> </path> <path id="minimap" d="M234 444C234 457.949 242.21 463 253 463"></path> <filter id="top-region-blur"> <feGaussianBlur in="SourceGraphic" stdDeviation="24"></feGaussianBlur> </filter> <linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset=".9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset="0.9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-up" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-up)"></rect> </mask> <mask id="fade-down" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-down)"></rect> </mask> <mask id="none" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="white"></rect> </mask> <linearGradient id="grad-symbol"> <stop offset="0.7" stop-color="white" stop-opacity="1"></stop> <stop offset=".95" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-symbol" maskContentUnits="userSpaceOnUse"> <rect width="290px" height="200px" fill="url(#grad-symbol)"></rect> </mask> </defs> <g clip-path="url(#corners)"> <rect fill="7c2e0e" x="0px" y="0px" width="290px" height="290px"></rect> <rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="290px"></rect> <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;"> <rect fill="none" x="0px" y="0px" width="290px" height="290px"></rect> <ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85"></ellipse> </g> <rect x="0" y="0" width="290" height="290" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect> </g> <text text-rendering="optimizeSpeed"> <textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a">  Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> </text> <rect x="16" y="16" width="258" height="258" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect> <path opacity="0.6" style="transform:translate(226px, 226px) scale(0.1)" id="Selection" fill="white" d="M 146.00,64.00 C 153.56,65.52 160.73,67.80 168.00,70.34 171.38,71.53 176.09,73.24 178.26,76.21 180.53,79.32 180.99,89.94 181.00,94.00 181.00,94.00 181.00,162.00 181.00,162.00 181.00,162.00 180.00,177.00 180.00,177.00 180.00,177.00 180.00,206.00 180.00,206.00 180.00,206.00 178.96,223.00 178.96,223.00 178.96,223.00 178.96,239.00 178.96,239.00 178.96,239.00 178.00,249.00 178.00,249.00 177.95,253.95 177.94,265.83 175.83,270.00 172.97,275.62 162.77,281.04 157.00,283.40 138.16,291.09 122.85,291.23 103.00,291.00 86.28,290.80 51.09,282.65 34.00,278.37 28.20,276.92 11.05,272.45 7.31,268.61 4.73,265.96 4.48,261.52 4.00,258.00 4.00,258.00 1.58,236.00 1.58,236.00 1.58,236.00 0.91,224.00 0.91,224.00 0.91,224.00 0.00,212.00 0.00,212.00 0.00,212.00 0.00,147.00 0.00,147.00 0.00,147.00 1.00,132.00 1.00,132.00 1.00,132.00 3.91,88.00 3.91,88.00 4.19,84.21 4.47,73.25 6.74,70.63 9.03,67.98 22.09,62.96 26.00,61.40 34.98,57.81 60.95,50.19 70.00,50.18 70.00,50.18 88.00,52.59 88.00,52.59 88.00,52.59 115.00,57.20 115.00,57.20 117.47,57.67 123.43,59.14 125.57,57.89 128.38,56.25 130.28,45.40 131.13,42.00 131.13,42.00 136.58,20.00 136.58,20.00 138.28,12.35 139.13,5.41 147.00,1.45 150.40,-0.25 154.30,-0.04 158.00,0.00 165.96,0.11 172.77,4.01 180.00,6.99 180.00,6.99 216.00,22.22 216.00,22.22 223.21,25.40 233.61,27.26 228.91,38.00 224.21,48.76 216.65,43.52 209.00,40.14 209.00,40.14 174.00,24.70 174.00,24.70 171.62,23.62 162.67,19.02 160.59,19.58 156.57,20.66 155.23,27.54 154.37,31.00 154.37,31.00 146.00,64.00 146.00,64.00 Z M 124.00,69.00 C 124.00,69.00 72.00,60.32 72.00,60.32 67.35,59.97 54.19,62.85 50.00,65.00 50.00,65.00 112.00,79.87 112.00,79.87 117.41,81.23 133.47,85.93 138.00,85.45 142.55,84.96 157.13,80.37 161.00,78.00 161.00,78.00 146.14,74.61 146.14,74.61 142.67,75.03 143.18,78.25 138.94,80.55 134.35,83.03 125.51,81.82 123.46,76.56 122.80,74.88 123.73,70.92 124.00,69.00 Z M 124.00,88.00 C 124.00,88.00 59.00,72.35 59.00,72.35 45.30,69.20 36.90,64.66 24.00,74.00 24.00,74.00 95.00,88.58 95.00,88.58 104.21,90.24 115.96,94.45 124.00,88.00 Z M 109.00,102.00 C 109.00,102.00 44.00,88.58 44.00,88.58 44.00,88.58 14.00,82.00 14.00,82.00 14.00,82.00 11.00,130.00 11.00,130.00 11.00,130.00 10.00,147.00 10.00,147.00 10.00,147.00 10.00,213.00 10.00,213.00 10.00,213.00 10.91,223.00 10.91,223.00 10.91,223.00 12.72,247.00 12.72,247.00 13.11,250.03 13.71,258.36 15.17,260.61 17.65,264.42 34.07,268.10 39.00,269.37 39.00,269.37 62.00,274.65 62.00,274.65 65.99,275.55 73.09,277.25 77.00,276.66 86.29,275.25 93.68,266.96 97.73,259.00 105.49,243.74 109.97,213.23 110.00,196.00 110.00,196.00 110.00,136.00 110.00,136.00 110.00,136.00 109.00,121.00 109.00,121.00 109.00,121.00 109.00,102.00 109.00,102.00 Z M 165.00,88.00 C 165.00,88.00 151.00,93.00 151.00,93.00 156.84,99.26 153.13,108.76 156.00,116.00 156.00,116.00 165.00,88.00 165.00,88.00 Z M 150.00,93.00 C 144.50,95.21 145.98,99.76 146.00,105.00 146.00,105.00 147.00,126.00 147.00,126.00 152.14,125.14 152.71,123.91 154.00,119.00 152.15,118.54 151.21,118.63 150.02,116.77 148.78,114.83 149.03,111.26 149.00,109.00 148.89,101.12 146.78,100.63 150.00,93.00 Z M 138.00,97.00 C 138.00,97.00 125.00,100.00 125.00,100.00 127.71,105.74 132.89,110.34 138.00,114.00 138.00,114.00 138.00,97.00 138.00,97.00 Z M 170.00,101.00 C 167.61,104.89 163.46,117.04 161.69,122.00 160.68,124.85 159.42,129.42 157.35,131.57 154.35,134.70 144.63,134.97 141.31,132.26 138.72,130.15 139.57,127.81 136.69,124.00 133.67,120.01 121.17,107.98 117.00,105.00 117.00,105.00 117.00,147.00 117.00,147.00 117.00,147.00 118.00,164.00 118.00,164.00 118.00,164.00 118.00,240.00 118.00,240.00 118.00,240.00 119.00,255.00 119.00,255.00 119.00,255.00 119.00,281.00 119.00,281.00 130.12,280.97 143.79,277.97 154.00,273.57 157.41,272.10 163.91,268.87 165.83,265.68 167.04,263.66 167.98,249.10 168.04,246.00 168.04,246.00 168.04,234.00 168.04,234.00 168.04,234.00 169.00,222.00 169.00,222.00 169.00,222.00 169.00,203.00 169.00,203.00 169.00,203.00 170.00,187.00 170.00,187.00 170.00,187.00 170.00,138.00 170.00,138.00 170.00,138.00 170.96,124.00 170.96,124.00 170.96,124.00 170.96,110.00 170.96,110.00 170.96,110.00 170.00,101.00 170.00,101.00 Z M 61.00,170.00 C 61.00,170.00 26.00,166.83 26.00,166.83 23.09,166.54 14.42,166.63 16.17,161.94 17.15,159.32 26.51,149.59 28.91,147.00 28.91,147.00 57.72,115.00 57.72,115.00 62.04,110.08 67.30,102.14 74.00,101.00 74.00,101.00 67.30,119.00 67.30,119.00 67.30,119.00 57.00,142.00 57.00,142.00 57.00,142.00 87.00,142.00 87.00,142.00 87.00,142.00 105.00,143.00 105.00,143.00 103.03,149.25 89.97,169.20 85.68,176.00 85.68,176.00 52.95,229.00 52.95,229.00 52.95,229.00 41.20,248.00 41.20,248.00 38.68,252.12 38.18,254.67 33.00,254.00 33.00,254.00 46.33,213.00 46.33,213.00 46.33,213.00 61.00,170.00 61.00,170.00 Z" width="200" height="200"></path>',
                clickMeText,
                '<g style="transform: scale(0.6);transform-origin: center;"><g style="animation: spin 25s linear infinite;transform-origin:center;color: #',
                colors[3],
                '">',
                merkaba[((uint8(hexBytes[10]) + 1) * (tokenId + 1)) % merkaba.length],
                '</g></g><style>@keyframes spin{from {transform: rotate(0deg)} to {transform: rotate(-360deg)}}</script></svg>'
            )
        );
        return string(abi.encodePacked('data:text/html;base64,', Base64.encode(abi.encodePacked(uniswap, html))));
    }
}
