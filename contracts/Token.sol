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
        string[8] memory merkaba = [
            '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" id="svg1" viewBox="0 0 1644.099 1644.099"><style>#svg1 polygon,#svg1 line{fill:none;stroke:#fff;stroke-miterlimit:10;stroke-width:3;}</style><g><polygon points="822.049,22.049 129.229,1222.049 1514.87,1222.049 "/><polygon points="422.049,129.229 422.049,1514.87 1622.049,822.049 "/><polygon points="129.229,422.049 822.049,1622.049 1514.87,422.05"/><polygon points="22.049,822.049 1222.049,1514.87 1222.049,129.229 "/><polygon style="stroke-width:7" points="1514.87,1222.049 822.049,1622.049 129.229,1222.049 129.229,422.049 822.049,22.049 1514.87,422.049 "/><polygon style="stroke-width:7" points="422.049,1514.87 22.049,822.049 422.049,129.229 1222.049,129.229 1622.049,822.049 1222.049,1514.87 "/><line x1="636.408" y1="1514.871" x2="1007.69" y2="129.23"/><line x1="422.049" y1="1514.87" x2="1222.049" y2="129.229"/><line x1="316.231" y1="1327.868" x2="1329.734" y2="314.364"/><line x1="129.229" y1="1222.049" x2="1514.87" y2="422.049"/><line x1="129.23" y1="1007.69" x2="1514.873" y2="636.408"/><line x1="22.049" y1="822.049" x2="1622.049" y2="822.049"/><line x1="129.23" y1="636.409" x2="1514.873" y2="1007.691"/><line x1="129.229" y1="422.049" x2="1514.87" y2="1222.049"/><line x1="316.231" y1="316.231" x2="1329.734" y2="1329.734"/><line x1="422.049" y1="129.229" x2="1222.049" y2="1514.87"/><line x1="636.409" y1="129.23" x2="1007.695" y2="1514.889"/><line x1="822.049" y1="22.049" x2="822.049" y2="1622.049"/></g></svg>',
            '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.c{fill: none; stroke: #fff; stroke-miterlimit: 10; stroke-width: 2.59px;}</style> </defs> <g id="a"/> <g id="b"> <g> <polygon class="c" points="419.86 337.5 225 450 30.14 337.5 30.14 112.5 225 0 419.86 112.5 419.86 337.5"/> <circle class="c" cx="225" cy="225" r="194.33" transform="translate(-93.2 225) rotate(-45)"/> <circle class="c" cx="225" cy="225" r="225"/> <polygon class="c" points="419.86 337.5 30.14 337.5 225 0 419.86 337.5"/> <line class="c" x1="225" y1="450" x2="225"/> <line class="c" x1="419.86" y1="112.5" x2="30.14" y2="337.5"/> <line class="c" x1="419.86" y1="337.5" x2="30.14" y2="112.5"/> <g> <circle class="c" cx="225" cy="225" r="112.01"/> <circle class="c" cx="225" cy="225" r="140.73" transform="translate(-93.2 225) rotate(-45)"/> </g> <polygon class="c" points="225 112.99 127.57 168.75 127.57 281 225 337.01 322.01 281.01 322.01 169.02 225 112.99"/> </g> </g> </svg>',
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.c{fill: none; stroke: #fff; stroke-miterlimit: 10; stroke-width: 2.66px;}</style> </defs> <g id="a"/> <g id="b"> <g> <polygon class="c" points="419.86 337.5 225 450 30.14 337.5 30.14 112.5 225 0 419.86 112.5 419.86 337.5"/> <polygon class="c" points="30.14 337.5 225 0 419.86 337.5 30.14 337.5"/> <circle class="c" cx="225" cy="225" r="225"/> <polygon class="c" points="419.86 112.08 225 449.58 30.14 112.08 419.86 112.08"/> <line class="c" x1="225" y1="225" x2="225" y2="0"/> <line class="c" x1="30.14" y1="337.5" x2="225" y2="225"/> <line class="c" x1="419.86" y1="337.5" x2="225" y2="225"/> <circle class="c" cx="225" cy="66.86" r="66.86"/> <circle class="c" cx="225" cy="416.15" r="33.43" transform="translate(-247.47 440.05) rotate(-64.5)"/> <circle class="c" cx="225" cy="225" r="56.25" transform="translate(-31.52 36.73) rotate(-8.72)"/> <circle cx="225" cy="225" r="18.28" fill="#fff"/> </g> </g> </svg>',
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.c{fill: none; stroke: #fff; stroke-miterlimit: 10; stroke-width: 2.59px;}</style> </defs> <g id="a"/> <g id="b"> <g> <g> <circle class="c" cx="225" cy="225" r="225"/> <polygon class="c" points="30.14 112.5 419.86 112.5 225 450 30.14 112.5"/> <line class="c" x1="225" y1="0" x2="225" y2="450"/> <line class="c" x1="30.14" y1="337.5" x2="419.86" y2="112.5"/> <line class="c" x1="30.14" y1="112.5" x2="419.86" y2="337.5"/> <polygon class="c" points="225 337.01 322.43 281.25 322.43 169 225 112.99 127.99 168.99 127.99 280.98 225 337.01"/> </g> <circle class="c" cx="225.21" cy="225.12" r="112.62"/> </g> </g></svg>',
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.w3.org/2000/svg" xmlns:cc="http://web.resource.org/cc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:svg="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:ns1="http://sozi.baierouge.fr" xmlns:xlink="http://www.w3.org/1999/xlink" id="svg2" version="1.1" viewBox="0 0 575.999971651997 575.9999732744195" inkscape:version="0.91 r13725"> <path id="path2842" style="stroke:#ffffff;stroke-width:3.3457;fill:none" d="m324.22 157.73 195.18 80.84 80.84 195.18-80.84 195.18-195.18 80.85-195.18-80.85-80.845-195.18 80.845-195.18 195.18-80.84z" transform="matrix(.95644 0 0 .95644 -22.095 -126.86)"/> <path id="path2957" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288-1e-13 -264l186.68 450.68 77.32-186.68-264-264"/> <path id="path2959" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288-186.68-186.68 450.68 186.68-77.324-186.68h-373.35"/> <path id="path2961" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288h-264l450.68-186.68-186.68-77.32-264 264"/> <path id="path2963" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288-186.68 186.68 186.68-450.68-186.68 77.32v373.35"/> <path id="path2965" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288-1e-13 264l-186.68-450.68-77.32 186.68 264 264"/> <path id="path2967" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288 186.68 186.68-450.68-186.68l77.324 186.68 373.35-6e-14"/> <path id="path2969" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288 264-3e-13 -450.68 186.68 186.68 77.324 264-264"/> <path id="path2971" style="stroke:#ffffff;stroke-width:3.2;fill:none" d="m288 288 186.68-186.68-186.68 450.68 186.68-77.324 3e-13 -373.35"/> <metadata> <rdf:RDF> <cc:Work> <dc:format>image/svg+xml</dc:format> <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/> <cc:license rdf:resource="http://creativecommons.org/licenses/publicdomain/"/> <dc:publisher> <cc:Agent rdf:about="http://openclipart.org/"> <dc:title>Openclipart</dc:title> </cc:Agent> </dc:publisher> <dc:title>octagon connections</dc:title> <dc:date>2011-04-21T15:41:32</dc:date> <dc:description>octagon connections</dc:description> <dc:source>https://openclipart.org/detail/133465/octagon-connections-by-10binary</dc:source> <dc:creator> <cc:Agent> <dc:title>10binary</dc:title> </cc:Agent> </dc:creator> <dc:subject> <rdf:Bag> <rdf:li>8</rdf:li> <rdf:li>connections</rdf:li> <rdf:li>lines</rdf:li> <rdf:li>octagon</rdf:li> <rdf:li>polygon</rdf:li> <rdf:li>sided</rdf:li> </rdf:Bag> </dc:subject> </cc:Work> <cc:License rdf:about="http://creativecommons.org/licenses/publicdomain/"> <cc:permits rdf:resource="http://creativecommons.org/ns#Reproduction"/> <cc:permits rdf:resource="http://creativecommons.org/ns#Distribution"/> <cc:permits rdf:resource="http://creativecommons.org/ns#DerivativeWorks"/> </cc:License> </rdf:RDF> </metadata></svg>',
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.c{fill: none; stroke: #fff; stroke-miterlimit: 10; stroke-width: 2.7px;}</style> </defs> <g id="a"/> <g id="b"> <g> <polygon class="c" points="393.39 79.17 225 370.83 56.61 79.17 393.39 79.17"/> <polygon class="c" points="56.61 370.83 225 79.17 393.39 370.83 56.61 370.83"/> <line class="c" x1="0" y1="225" x2="450" y2="225"/> <line class="c" x1="225" x2="225" y2="450"/> <line class="c" x1="56.61" y1="79.17" x2="309.19" y2="225"/> <line class="c" x1="393.39" y1="79.17" x2="141.6" y2="225"/> <line class="c" x1="56.61" y1="370.83" x2="309.19" y2="225"/> <line class="c" x1="393.39" y1="370.83" x2="141.6" y2="225"/> <circle class="c" cx="225" cy="225" r="145.83" transform="translate(-93.2 225) rotate(-45)"/> <circle class="c" cx="225" cy="225" r="225" transform="translate(-93.2 225) rotate(-45)"/> </g> </g></svg>',
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.c{fill: none; stroke: #fff; stroke-miterlimit: 10; stroke-width: 2.74px;}</style> </defs> <g id="a"/> <g id="b"> <g> <circle class="c" cx="225" cy="225" r="225" transform="translate(-93.2 225) rotate(-45)"/> <circle class="c" cx="225" cy="225" r="77.73" transform="translate(-22.06 425.53) rotate(-84.06)"/> <circle class="c" cx="224.66" cy="224.97" r="96.42"/> <g> <line class="c" x1="224.66" y1=".1" x2="146.41" y2="280.27"/> <line class="c" x1="11" y1="155.82" x2="253.28" y2="316.82"/> <line class="c" x1="93.08" y1="407.15" x2="321.07" y2="226.48"/> <line class="c" x1="357.47" y1="406.75" x2="256.09" y2="134.09"/> <line class="c" x1="438.79" y1="155.18" x2="148.15" y2="167.34"/> <polygon class="c" points="92.59 406.47 10.97 155.26 224.66 0 438.36 155.26 356.73 406.47 92.59 406.47"/> </g> <g> <line class="c" x1="130.08" y1="70.67" x2="194.36" y2="296.61"/> <line class="c" x1="48.62" y1="268.02" x2="283.37" y2="276.7"/> <line class="c" x1="211.14" y1="406.47" x2="291.94" y2="185.9"/> <line class="c" x1="393.04" y1="294.69" x2="208.23" y2="149.68"/> <line class="c" x1="342.94" y1="87.15" x2="147.92" y2="218.11"/> <polygon class="c" points="210.52 406.21 48.36 267.64 130.04 70.6 342.68 87.39 392.42 294.81 210.52 406.21"/> </g> </g> </g></svg>',
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"> <defs> <style>.q{fill: #ffffff;}</style> </defs> <g id="a"/> <g id="b"/> <g id="c"/> <g id="d"> <g> <path class="q" d="M323.95,395.89H127.21L28.84,225.5,127.21,55.12h196.74l98.37,170.38-98.37,170.38Zm-193.74-5.19h190.74l95.37-165.19L320.96,60.31H130.21L34.84,225.5l95.37,165.19Z"/> <path class="q" d="M328.88,404.4H122.29l-.26-.45L19,225.5l.26-.45L122.29,46.6h206.58l.26,.44,103.03,178.45-.26,.44-103.03,178.46Zm-205.55-1.78h204.52l102.26-177.12L327.84,48.38H123.32L21.06,225.5l102.26,177.12Z"/> <path class="q" d="M322.45,394.18c-.15,0-.31-.04-.44-.12L31.4,226.27c-.28-.16-.45-.45-.45-.77s.17-.61,.45-.77L322.01,56.94c.28-.16,.61-.16,.89,0,.28,.16,.45,.45,.45,.77V393.29c0,.32-.17,.61-.45,.77-.14,.08-.29,.12-.45,.12ZM33.62,225.5l287.94,166.24V59.26L33.62,225.5Z"/> <path class="q" d="M128.71,394.18c-.15,0-.31-.04-.45-.12-.28-.16-.44-.45-.44-.77V57.72c0-.32,.17-.61,.44-.77,.28-.16,.61-.16,.89,0L419.77,224.73c.28,.16,.45,.45,.45,.77s-.17,.61-.45,.77L129.16,394.06c-.14,.08-.29,.12-.44,.12Zm.89-334.92V391.75L417.54,225.5,129.6,59.26Z"/> <rect class="q" x="224.69" y="31.76" width="1.78" height="387.48" transform="translate(-82.53 143) rotate(-30)"/> <rect class="q" x="31.84" y="224.61" width="387.48" height="1.78"/> <rect class="q" x="31.84" y="224.61" width="387.48" height="1.78" transform="translate(-82.44 308.32) rotate(-60.04)"/> <path class="q" d="M224.9,323.53c-53.82,0-97.6-43.78-97.6-97.6s43.78-97.6,97.6-97.6,97.6,43.78,97.6,97.6-43.79,97.6-97.6,97.6Zm0-193.42c-52.83,0-95.82,42.98-95.82,95.82s42.99,95.82,95.82,95.82,95.82-42.98,95.82-95.82-42.99-95.82-95.82-95.82Z"/> <path class="q" d="M224.9,296.67c-39,0-70.74-31.73-70.74-70.74s31.73-70.74,70.74-70.74,70.73,31.73,70.73,70.74-31.73,70.74-70.73,70.74Zm0-139.69c-38.02,0-68.96,30.93-68.96,68.96s30.94,68.96,68.96,68.96,68.96-30.93,68.96-68.96-30.93-68.96-68.96-68.96Z"/> <path class="q" d="M224.9,287.52c-33.96,0-61.59-27.63-61.59-61.59s27.63-61.59,61.59-61.59,61.59,27.63,61.59,61.59-27.63,61.59-61.59,61.59Zm0-121.4c-32.98,0-59.81,26.83-59.81,59.81s26.83,59.81,59.81,59.81,59.81-26.83,59.81-59.81-26.83-59.81-59.81-59.81Z"/> <path class="q" d="M234.3,225.93c0,5.19-4.21,9.4-9.4,9.4s-9.41-4.21-9.41-9.4,4.21-9.4,9.41-9.4,9.4,4.21,9.4,9.4Z"/> <path class="q" d="M101.04,141.23c0,2.55-2.07,4.61-4.61,4.61s-4.61-2.06-4.61-4.61,2.06-4.6,4.61-4.6,4.61,2.06,4.61,4.6Z"/> <path class="q" d="M231.49,70.12c0,2.54-2.06,4.6-4.6,4.6s-4.61-2.06-4.61-4.6,2.06-4.61,4.61-4.61,4.6,2.06,4.6,4.61Z"/> <path class="q" d="M365.43,146.9c0,2.54-2.07,4.61-4.61,4.61s-4.61-2.06-4.61-4.61,2.06-4.6,4.61-4.6,4.61,2.06,4.61,4.6Z"/> <path class="q" d="M367.61,299.6c0,2.55-2.06,4.61-4.6,4.61s-4.61-2.06-4.61-4.61,2.06-4.6,4.61-4.6,4.6,2.06,4.6,4.6Z"/> <path class="q" d="M92.75,299.6c0,2.55-2.06,4.61-4.6,4.61s-4.61-2.06-4.61-4.61,2.06-4.6,4.61-4.6,4.6,2.06,4.6,4.6Z"/> <path class="q" d="M231.05,382.06c0,2.55-2.06,4.61-4.61,4.61s-4.61-2.06-4.61-4.61,2.07-4.6,4.61-4.6,4.61,2.06,4.61,4.6Z"/> <path class="q" d="M127.85,47.49c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.25-5.04-5.04,2.26-5.04,5.04-5.04,5.04,2.26,5.04,5.04Z"/> <path class="q" d="M333.34,47.49c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.25-5.04-5.04,2.26-5.04,5.04-5.04,5.04,2.26,5.04,5.04Z"/> <path class="q" d="M436.3,225.93c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.26-5.04-5.04,2.25-5.04,5.04-5.04,5.04,2.25,5.04,5.04Z"/> <path class="q" d="M24.45,225.93c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.26-5.04-5.04,2.26-5.04,5.04-5.04,5.04,2.25,5.04,5.04Z"/> <path class="q" d="M127.41,403.5c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.25-5.04-5.04,2.25-5.04,5.04-5.04,5.04,2.26,5.04,5.04Z"/> <path class="q" d="M332.9,403.5c0,2.78-2.26,5.04-5.04,5.04s-5.04-2.25-5.04-5.04,2.25-5.04,5.04-5.04,5.04,2.26,5.04,5.04Z"/> <path class="q" d="M129.84,89.81c-17.58,0-31.89-14.31-31.89-31.89s14.31-31.89,31.89-31.89,31.89,14.3,31.89,31.89-14.31,31.89-31.89,31.89Zm0-61.99c-16.6,0-30.11,13.51-30.11,30.11s13.51,30.11,30.11,30.11,30.11-13.51,30.11-30.11-13.51-30.11-30.11-30.11Z"/> <path class="q" d="M322.02,89.81c-17.58,0-31.89-14.31-31.89-31.89s14.31-31.89,31.89-31.89,31.88,14.3,31.88,31.89-14.3,31.89-31.88,31.89Zm0-61.99c-16.6,0-30.11,13.51-30.11,30.11s13.51,30.11,30.11,30.11,30.1-13.51,30.1-30.11-13.5-30.11-30.1-30.11Z"/> <path class="q" d="M31.89,257.82c-17.58,0-31.89-14.31-31.89-31.89s14.31-31.89,31.89-31.89,31.89,14.31,31.89,31.89-14.31,31.89-31.89,31.89Zm0-62c-16.6,0-30.11,13.51-30.11,30.11s13.51,30.11,30.11,30.11,30.11-13.51,30.11-30.11-13.51-30.11-30.11-30.11Z"/> <path class="q" d="M418.11,257.82c-17.58,0-31.88-14.31-31.88-31.89s14.3-31.89,31.88-31.89,31.89,14.31,31.89,31.89-14.31,31.89-31.89,31.89Zm0-62c-16.6,0-30.1,13.51-30.1,30.11s13.5,30.11,30.1,30.11,30.11-13.51,30.11-30.11-13.51-30.11-30.11-30.11Z"/> <path class="q" d="M130.46,423.96c-17.58,0-31.89-14.31-31.89-31.89s14.31-31.89,31.89-31.89,31.88,14.3,31.88,31.89-14.3,31.89-31.88,31.89Zm0-61.99c-16.6,0-30.11,13.51-30.11,30.11s13.51,30.11,30.11,30.11,30.1-13.51,30.1-30.11-13.5-30.11-30.1-30.11Z"/> <path class="q" d="M320.78,423.96c-17.58,0-31.89-14.31-31.89-31.89s14.31-31.89,31.89-31.89,31.89,14.3,31.89,31.89-14.31,31.89-31.89,31.89Zm0-61.99c-16.6,0-30.11,13.51-30.11,30.11s13.51,30.11,30.11,30.11,30.11-13.51,30.11-30.11-13.51-30.11-30.11-30.11Z"/> </g> </g> <g id="e"/> <g id="f"/> <g id="g"/> <g id="h"/> <g id="i"/> <g id="j"/> <g id="k"/> <g id="l"/> <g id="m"/> <g id="n"/> <g id="o"/> <g id="p"/></svg>'
        ];

        string
            memory html = unicode'<link rel="stylesheet" type="text/css" href="https://play.ertdfgcvb.xyz/css/simple_console.css"><style type="text/css" media="screen">html, body {	padding: 0;	margin: 0;	font-size: 1em;	line-height: 1.2;font-family: "Simple Console", monospace;}pre {	position: absolute;	margin:0;padding:0;	left:0;	top:0;width:1000px;height:2000px;color: white;opacity: 0.5;font-family: inherit;transform: scale(0.7);transform-origin:10px 10px;}</style><audio src="" id="song1" volume="0.1" style="display: none;" loop="true"></audio><audio src="" id="song2" volume="0.1" style="display: none;" loop="true"></audio><script>const songs = [song1, song2];const tracks = location.hash.slice(1).split("#");const betterQuality = ["", ""];for(let i =0;i<songs.length;i++) songs[i].src = (navigator.onLine && betterQuality[i]) || tracks[i];</script>';

        string[4] memory filters = [
            '',
            '173%22%20cy%3D%22129%22%20r%3D%22120px%22%20fill%3D%22%23',
            '353%22%20cy%3D%22157%22%20r%3D%22120px%22%20fill%3D%22%23',
            '237%22%20cy%3D%22314%22%20r%3D%22100px%22%20fill%3D%22%23'
        ];
        bytes memory hexBytes = abi.encodePacked(Strings.toHexString(uint256(uint160(msg.sender))));
        for (uint8 i = 0; i < 4; i++) {
            for (uint8 j = 0; j < 3; j++) {
                filters[i] = string(abi.encodePacked(filters[i], hexBytes[i * 3 + (tokenId % 15) + 2 + j], hexBytes[i * 3 + (tokenId % 15) + 3 + j]));
            }
        }

        string memory clickMeText = '';
        if (uint8((uint8(hexBytes[18]) + 1) * (tokenId + 1)) > 128) {
            clickMeText = '<g style="transform:translate(29px, 244px)"> <rect width="54px" height="17.3333px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"></rect><text x="8px" y="11.333px" font-family="\'Courier New\', monospace" font-size="8px" fill="white">Click me</text></g>';
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
                '<image href="',
                abi.encodePacked(
                    'data:image/svg+xml;base64,',
                    Base64.encode(abi.encodePacked(merkaba[((uint8(hexBytes[10]) + 1) * (tokenId + 1)) % merkaba.length]))
                ),
                '" width="200" height="200" x="45" y="45" style="animation: spin 25s linear infinite;transform-origin:center" /><style>@keyframes spin{from {transform: rotate(0deg)} to {transform: rotate(-360deg)}}</script></svg>'
            )
        );
        return string(abi.encodePacked('data:text/html;base64,', Base64.encode(abi.encodePacked(uniswap, html))));
    }
}
