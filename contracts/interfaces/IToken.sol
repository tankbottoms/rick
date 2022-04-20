// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '../enums/AssetDataType.sol';

interface IToken {
    function contractURI() external view returns (string memory);

    function setOpenseaContractUri(string calldata _uri) external;

    function claim(uint256 numTokens) external payable;

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof) external payable;

    function airdrop(address[] calldata to) external;

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

    function rollState(uint256 tokenId) external payable;

    function getInterestingContent() external view returns (string memory);
}
