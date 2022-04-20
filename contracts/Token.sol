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
error ALREADY_ROLLED();
error TOKEN_NOT_FOUND();

contract Token is IToken, ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IStorage public assets;

    uint256 private _totalSupply;
    string public openseaMetadata;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant RICK_PRICE = 0.005 ether;
    uint256 public price = 0.04 ether;
    uint256 public whitelistPrice = 0.01 ether;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_ADDRESS = 15;
    uint256 public constant MAX_PER_ADDRESS_WHITELIST = 25;
    bool public publicSaleActive = false;
    bool public whitelistSaleActive = true;
    bytes32 public whitelistMerkleRoot;

    mapping(uint256 => bool) private _ricked;
    mapping(uint256 => uint256) private _random;
    mapping(address => uint256) private _mintedPerAddress;

    event RicksMinted(address sender, uint256 mintedCount, uint256 lastMintedTokenID);

    constructor(IStorage _assets) ERC721('Rick', 'RICK') {
        assets = _assets;
    }

    function contractURI() public view override returns (string memory) {
        return openseaMetadata;
    }

    function setOpenseaContractUri(string calldata _uri) public override onlyOwner {
        require(bytes(_uri).length == 0, 'Token: Opensea contract URI cannot be empty.');

        openseaMetadata = _uri;
    }

    function _bulkMint(
        uint256 numTokens,
        address destination,
        bool roll
    ) private {
        if (tokensMinted() + numTokens > MAX_SUPPLY) {
            revert EXCEEDS_TOKEN_SUPPLY();
        }

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(destination, newItemId);
            if (roll) {
                _ricked[newItemId] = true;
            }
            _random[newItemId] = (block.timestamp * (i + 1)) * (block.difficulty * (newItemId + 1)) + uint256(uint160(msg.sender));
            _tokenIds.increment();
        }
        _mintedPerAddress[destination] += numTokens;
        emit RicksMinted(destination, numTokens, _tokenIds.current() - 1);
    }

    function claim(uint256 numTokens) public payable virtual override nonReentrant {
        if (!publicSaleActive) {
            revert PUBLIC_SALE_NOT_ACTIVE();
        }

        if (price * numTokens > msg.value) {
            revert INCORRECT_TOKEN_AMOUNT();
        }

        if (_mintedPerAddress[msg.sender] + numTokens > MAX_PER_ADDRESS) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }

        if (numTokens > MAX_PER_TX) {
            revert TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
        }

        _bulkMint(numTokens, msg.sender, msg.sender == owner());
    }

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof) public payable virtual override nonReentrant {
        if (!whitelistSaleActive) {
            revert WHITELIST_SALE_NOT_ACTIVE();
        }

        if (!MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender, numTokens)))) {
            revert ADDRESS_NOT_IN_WHITELIST();
        }

        if (_mintedPerAddress[msg.sender] == MAX_PER_ADDRESS_WHITELIST || _mintedPerAddress[msg.sender] + numTokens > MAX_PER_ADDRESS_WHITELIST) {
            revert EXCEEDS_WALLET_ALLOWANCE();
        }

        if (whitelistPrice * numTokens < msg.value) {
            revert INSUFFICIENT_FUNDS();
        }

        _bulkMint(numTokens, msg.sender, true);
    }

    function airdrop(address[] calldata to) public override onlyOwner {
        if (tokensMinted() + to.length > MAX_SUPPLY) {
            revert EXCEEDS_TOKEN_SUPPLY();
        }

        for (uint256 i = 0; i < to.length; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(to[i], newItemId);
            _tokenIds.increment();
        }
    }

    /**
     * By default the NFT is a colorful NFT with a Merkaba design pattern.
     * However you can "roll" the NFT state to reveal a Click Me Button.
     * When the button is pressed, then the Rick SVG is revealed and music plays in a loop.
     * If the user pays into rollState for a particular token, it will permanently switch 
     to the "ricked" state where the click-me button will appear all the time. 
     Separately, tokens that haven't been "ricked" will pseudo-randomly show the click-me button as 
     well based on entropy from user address, and blockchain state.
     **/
    function rollState(uint256 tokenId) public payable override nonReentrant {
        if (_ricked[tokenId]) {
            revert ALREADY_ROLLED();
        }

        if (msg.value < RICK_PRICE) {
            revert INSUFFICIENT_FUNDS();
        }

        _ricked[tokenId] = true;
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

    function getInterestingContent() public view override returns (string memory) {
        return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(assets.getAssetContentForId(0))));
    }

    function withdrawAll() public payable override onlyOwner {
        require(payable(msg.sender).send(address(this).balance), 'Token: Withdraw all failed.');
    }

    function tokensMinted() public view override returns (uint256) {
        return _tokenIds.current();
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

    function dataUri(uint256 tokenId) public view override returns (string memory) {
        if (_tokenIds.current() <= tokenId) {
            revert TOKEN_NOT_FOUND();
        }

        bytes memory hexBytes = abi.encodePacked(Strings.toHexString(uint256(uint160(msg.sender))));

        uint8[3] memory ints;
        ints[0] = 18;
        ints[1] = uint8(_random[tokenId] % 256);
        ints[2] = ints[1] % ints[0];

        bool[1] memory bools = [ints[2] != 2 && ints[2] != 3 && ints[2] != 7 && !_ricked[tokenId]]; // spin or don't spin?

        /**
         * color0, color1, color2, color3
         */
        string[9] memory strings;
        for (uint8 i = 0; i < 4; i++) {
            for (uint8 j = 0; j < 3; j++) {
                strings[i] = string(abi.encodePacked(strings[i], hexBytes[i * 3 + (tokenId % 15) + 2 + j], hexBytes[i * 3 + (tokenId % 15) + 3 + j]));
            }
        }

        string memory audioBase64URI;

        // CLICK ME
        if (_ricked[tokenId] || ints[1] > 128) {
            strings[
                4
            ] = '<g style="transform:translate(36px, 241px);cursor:pointer" onclick="startRickRoll()"> <rect width="36px" height="17.3333px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"></rect><text id="playPauseButton" x="8px" y="11.333px" font-family="monospace" font-size="8px" fill="white">PLAY</text></g>';

            // Add Rick Roll SVG to JAVASCRIPT
            strings[8] = string(
                abi.encodePacked(
                    'const rickRollSvg = `',
                    string(assets.getAssetContentForId(1)),
                    '`;function init(){song1.src = location.hash.slice(1).split("#")[0]}function play(){if(!song1.src || song1.src.indexOf("data")===-1)init();try{song1.paused?(song1.play(),playPauseButton.innerHTML="PAUSE",playPauseButton.previousElementSibling.style.width="41px"):(song1.pause(),playPauseButton.innerHTML="PLAY",playPauseButton.previousElementSibling.style.width="36px")}catch(e){}}function startRickRoll(){shape.innerHTML=rickRollSvg;shape.style.transform="scale(0.6) translate(-135px, -90px)";play()}'
                )
            );

            audioBase64URI = getAssetBase64(uint64(0), AssetDataType.AUDIO_MP3);
        }

        // SHAPE COLOR
        if (ints[1] % 2 == 0) {
            strings[5] = 'ffffff';
        } else {
            strings[ints[1] % 4];
        }

        // BG
        strings[6] = string(
            abi.encodePacked(
                '<svg width="500" height="500" viewBox="0 0 290 290"> <defs> <filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Crect%20width%3D%22290px%22%20height%3D%22290px%22%20fill%3D%22%23',
                strings[0],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p1" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Ccircle%20cx%3D%22173%22%20cy%3D%22129%22%20r%3D%22120px%22%20fill%3D%22%23',
                strings[1],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p2" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%3Ccircle%20cx%3D%22353%22%20cy%3D%22157%22%20r%3D%22120px%22%20fill%3D%22%23',
                strings[2],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p3" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%20%3Ccircle%20cx%3D%22237%22%20cy%3D%22314%22%20r%3D%22100px%22%20fill%3D%22%23',
                strings[3]
            )
        );
        strings[6] = string(
            abi.encodePacked(
                strings[6],
                '%22%20style%3D%22animation%3A%20move-around%2010s%20linear%20infinite%22%2F%3E%20%3Cstyle%3E%40keyframes%20move-around%7B0%25%7Btransform%3A%20translate(0%2C%200)%3B%7D25%25%7Btransform%3A%20translate(-290px%2C%20-290px)%3B%7D50%25%7Btransform%3A%20translate(290px%2C%20-290px)%3B%7D75%25%7Btransform%3A%20translate(-290px%2C%20290px)%3B%7D100%25%7Btransform%3A%20translate(0%2C%200)%3B%7D%7D%3C%2Fstyle%3E%3C%2Fsvg%3E"> </feImage><feBlend mode="overlay" in="p0" in2="p1"></feBlend> <feBlend mode="exclusion" in2="p2"></feBlend> <feBlend mode="overlay" in2="p3" result="blendOut"></feBlend> <feGaussianBlur in="blendOut" stdDeviation="42"></feGaussianBlur> </filter> <clipPath id="corners"> <rect width="290" height="290" rx="42" ry="42"></rect> </clipPath> <path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V250 A28 28 0 0 1 250 278 H40 A28 28 0 0 1 12 250 V40 A28 28 0 0 1 40 12 z"> </path> <path id="minimap" d="M234 444C234 457.949 242.21 463 253 463"></path> <filter id="top-region-blur"> <feGaussianBlur in="SourceGraphic" stdDeviation="24"></feGaussianBlur> </filter> <linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset=".9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset="0.9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-up" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-up)"></rect> </mask> <mask id="fade-down" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-down)"></rect> </mask> <mask id="none" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="white"></rect> </mask> <linearGradient id="grad-symbol"> <stop offset="0.7" stop-color="white" stop-opacity="1"></stop> <stop offset=".95" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-symbol" maskContentUnits="userSpaceOnUse"> <rect width="290px" height="200px" fill="url(#grad-symbol)"></rect> </mask> </defs> <g clip-path="url(#corners)"> <rect fill="7c2e0e" x="0px" y="0px" width="290px" height="290px"></rect> <rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="290px"></rect> <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;"> <rect fill="none" x="0px" y="0px" width="290px" height="290px"></rect> <ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85"></ellipse> </g> <rect x="0" y="0" width="290" height="290" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect> </g> <text text-rendering="optimizeSpeed"> <textPath startOffset="-100%" fill="white" font-family="monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="0%" fill="white" font-family="monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="50%" fill="white" font-family="monospace" font-size="9px" xlink:href="#text-path-a">  Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="-50%" fill="white" font-family="monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> </text> <rect x="16" y="16" width="258" height="258" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect><g id="shape" style="transform: scale(0.6);transform-origin: center;"><g style="'
            )
        );

        if (bools[0]) {
            strings[6] = string(abi.encodePacked(strings[6], 'animation: spin 25s linear infinite;'));
        }

        strings[6] = string(
            abi.encodePacked(
                strings[6],
                'transform-origin:center;color: #',
                strings[5],
                '">',
                string(assets.getAssetContentForId(ints[2] + 2)), // SHAPE
                '</g></g><style>@keyframes spin{from {transform: rotate(0deg)} to {transform: rotate(-360deg)}}</style><g opacity="0.6" style="transform:translate(235px, 235px) scale(0.07);color:#fff">',
                string(assets.getAssetContentForId(20)), //JUICEBOX LOGO PATH
                '</g>',
                // click me button
                strings[4],
                '</svg>'
            )
        );

        // HTML
        strings[7] = '<audio src="" id="song1" volume="0.1" style="display: none;" loop="true"></audio><script>';

        string memory html = string(abi.encodePacked(strings[6], strings[7], strings[8], '</script>'));

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "RickRoll No.',
                Strings.toString(tokenId),
                '", "description": "Fully on-chain, Rick Astley RickRoll MP3 SVG NFT", "image": "',
                getAssetBase64(uint64(1), AssetDataType.IMAGE_SVG),
                '", "animation_url": "',
                string(abi.encodePacked('data:text/html;base64,', Base64.encode(bytes(html)))),
                '#',
                audioBase64URI,
                '", "attributes":[{"trait_type":"RickRolled","value":"yes"}]}'
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}
