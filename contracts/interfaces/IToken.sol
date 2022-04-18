// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IToken {
    function totalSupply() external view returns (uint256);
    function tokenUri(uint256 tokenId) external view returns (string memory);
    function getAudioAssetBase64(uint16 _assetId) external view returns (string memory);
}
