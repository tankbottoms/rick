// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IStorage {
  function createAsset(uint24 _bufferLengthInBytes) external;
  function appendAssetBuffer(uint16 _assetId, uint256[] memory _buffer) external;
  function getAssetBytes(uint16 _assetId) external view returns (bytes memory _bytes);
}
