// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '../enums/AssetDataType.sol';

interface IToken {
    function claim(uint256 numTokens) external payable;

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof) external payable;

    function airdrop(address[] memory to) external;

    function claimForFriend(uint256 numTokens, address walletAddress) external payable;

    function ownerClaim(uint256 numTokens) external;

    function founderClaim(uint256 numTokens) external;

    function flipRickState(bool _flip) external payable;

    function totalSupply() external view returns (uint256);

    function dataUri(uint256 tokenId) external view returns (string memory);

    function tokenUri(uint256 tokenId) external view returns (string memory);

    function getAssetBase64(uint64 _assetId, AssetDataType _assetType) external view returns (string memory);

    function withdrawAll() external payable;

    function tokensMinted() external view returns (uint256);

    function isSaleActive() external view returns (bool);

    function isWhitelistSaleActive() external view returns (bool);

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external;

    function setSaleActive(bool status) external;

    function setWhitelistSaleActive(bool status) external;

    function setFounderList(address[] calldata founderAddr) external;

    /*
    function totalSupply() external view returns (uint256);

    function tokenUri(uint256 tokenId) external view returns (string memory);

    function getAudioAssetBase64(uint16 _assetId) external view returns (string memory);

    function example() external view returns (string memory);
    */
}
