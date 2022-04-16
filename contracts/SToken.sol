// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Base64 } from './libraries/Base64.sol';
import { SStorage } from './SStorage.sol';

error NOT_IN_FOUNDER_LIST();
error ALL_TOKENS_MINTED();
error EXCEEDS_TOKEN_SUPPLY();
error PUBLIC_SALE_NOT_ACTIVE();
error WHITELIST_SALE_NOT_ACTIVE();
error TOKENS_TO_CLAIM_MUST_BE_POSITIVE();
error TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
error INCORRECT_TOKEN_AMOUNT();
error INSUFFICIENT_FUNDS();
error EXCEEDS_WALLET_ALLOWANCE();
error ADDRESS_NOT_IN_WHITELIST();
error NOT_READY_TO_ROLL();

contract SToken is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    SStorage public assets;
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
    
    event RicksMinted(
        address sender,
        uint256 minted_count,
        uint256 lastMintedTokenID
    );

    modifier isFounder() {
        if(founderList[msg.sender]) {
            revert NOT_IN_FOUNDER_LIST();
        }
        _;
    }
    constructor(SStorage _assets) ERC721('Rick', 'RICK') {
        assets = _assets;
    }

    function _bulkMint(uint256 numTokens, address destination) private {
        if(tokensMinted() <= MAX_SUPPLY){
            revert ALL_TOKENS_MINTED();
        }
        if(tokensMinted() + numTokens <= MAX_SUPPLY){
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

    function claim(uint256 numTokens) public payable virtual nonReentrant {
        if(publicSaleActive){
            revert PUBLIC_SALE_NOT_ACTIVE();
        }
        if(numTokens > 0){
            revert TOKENS_TO_CLAIM_MUST_BE_POSITIVE();
        }
        if(price * numTokens <= msg.value){
            revert INCORRECT_TOKEN_AMOUNT();
        }
        if(_mintedPerAddress[msg.sender] + numTokens <= MAX_PER_ADDRESS){
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if(numTokens <= MAX_PER_TX){
            revert TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
        }
        _bulkMint(numTokens, msg.sender);
    }

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof)
        external
        payable
        virtual
        nonReentrant
    {
        if(whitelistSaleActive){
            revert WHITELIST_SALE_NOT_ACTIVE();
        }
        if(numTokens > 0){
            revert TOKENS_TO_CLAIM_MUST_BE_POSITIVE();
        }
        if(_whitelistMintedPerAddress[msg.sender] <= MAX_PER_ADDRESS_WHITELIST){
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender)))){
            revert ADDRESS_NOT_IN_WHITELIST();
        }
        if(whitelistPrice * numTokens <= msg.value){
            revert INSUFFICIENT_FUNDS();
        }                
        _bulkMint(numTokens, msg.sender);
    }

    function airdrop(address[] memory to) public onlyOwner {
        if(tokensMinted() + to.length <= MAX_SUPPLY){
            revert EXCEEDS_TOKEN_SUPPLY();
        }                   
        for (uint256 i = 0; i < to.length; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(to[i], newItemId);
            _tokenIds.increment();         
        }
    }

    function claimForFriend(uint256 numTokens, address walletAddress)
        public
        payable
        virtual
    {
        if(publicSaleActive){
            revert PUBLIC_SALE_NOT_ACTIVE();
        }
        if(price * numTokens <= msg.value){
            revert INSUFFICIENT_FUNDS();
        }
        if(_mintedPerAddress[msg.sender] + numTokens <= MAX_PER_ADDRESS){
            revert EXCEEDS_WALLET_ALLOWANCE();
        }
        if(numTokens <= MAX_PER_TX){
            revert TOKENS_TO_MINT_EXCEEDS_ALLOWANCE();
        }        
        _bulkMint(numTokens, walletAddress);
    }

    function ownerClaim(uint256 numTokens) public onlyOwner {
        _bulkMint(numTokens, msg.sender);
    }

    function founderClaim(uint256 numTokens) public isFounder {
        if(numTokens > 0){
            revert TOKENS_TO_CLAIM_MUST_BE_POSITIVE();
        }
        if(_mintedPerAddress[msg.sender] + numTokens <=
                MAX_PER_FOUNDER_ADDRESS){
            revert EXCEEDS_WALLET_ALLOWANCE();
            }                
        _bulkMint(numTokens, msg.sender);
    }

/*
    By default the NFT is a colorful NFT with a Merkaba design pattern. 
    However you can flip the NFT state to reveal a Click Me Button. 
    When the button is pressed, then the Rick SVG is revealed and music plays in a loop.
    The Rick mode stays for 72 hours for normal users and 1 week for founders, afterwhich the state is flipped back.
    Users must send the setupRick  to the contract to flip the state where the founders can just flip for gas.
    Remove any links to any files externally from the contract, including the high-resolution Rick.    

*/
    function flipRickState(bool _flip) public payable nonReentrant {
        if (!readyToRoll) {
            revert NOT_READY_TO_ROLL();
        }
        if (founderList[msg.sender]){
            readyToRoll = true;         
        } else {
            if(msg.value != setupRick){
                revert INSUFFICIENT_FUNDS();
            }
            readyToRoll = true;
        }
    }

    function setMainSVG(uint256 _graphicId) public {
        graphicId = _graphicId;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function dataUri(uint256 tokenId) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked(
                    '{"name": "RickRoll #',
                    Strings.toString(tokenId),
                    '", "description": "Fully on-chain, Rick Astley RickRoll MP3 SVG NFT",',
                    'data:audio/mp3;base64,', Base64.encode(abi.encodePacked(assets.getAssetForId(tokenId))),
                    ',"attributes":[{"trait_type":"RickRolled","value":"yes"}]}'
                    ))));        
        return string(abi.encodePacked('data:application/json;base64,', json));        
    }
    
    function tokenUri(uint256 tokenId) public view returns (string memory) {    
        // return getAudioAssetBase64(tokenId);
        return dataUri(tokenId);
    }

    function getAudioAssetBase64(uint256 _assetId) public view returns (string memory) {
        return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(abi.encodePacked(assets.getAssetForId(_assetId)))));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function tokensMinted() public view returns (uint256) {
        return _tokenIds.current() - 1;
    }

    function isSaleActive() external view returns (bool) {
        return publicSaleActive;
    }

    function isWhitelistSaleActive() external view returns (bool) {
        return whitelistSaleActive;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setSaleActive(bool status) public onlyOwner {
        publicSaleActive = status;
    }

    function setWhitelistSaleActive(bool status) public onlyOwner {
        whitelistSaleActive = status;
    }

    function setFounderList(address[] calldata founderAddr) external onlyOwner {
        for (uint256 i = 0; i < founderAddr.length; i++) {
            founderList[founderAddr[i]] = true;
        }
    }

}
