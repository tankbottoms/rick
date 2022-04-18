// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStorage {
    function createAsset(
        uint64 _assetId,
        bytes32 _assetKey,
        bytes32[] memory _content,
        uint64 fileSizeInBytes
    ) external;

    function appendAssetContent(
        uint64 _assetId,
        bytes32 _assetKey,
        bytes32[] calldata _content
    ) external;

    function setAssetAttribute(
        uint64 _assetId,
        string calldata _attrName,
        uint32 _attrType,
        bytes32[] calldata _value
    ) external;

    function getAssetContentForId(uint64 _assetId) external view returns (bytes memory _content);

    function getAssetKeysForId(uint64 _assetId) external view returns (bytes32[] memory);

    function getContentForKey(bytes32 _contentKey) external view returns (bytes32[] memory);

    function getAssetSize(uint64 _assetId) external view returns (uint64);

    function getAssetInfoAttribute(uint64 _assetId, string calldata _attr) external view returns (bytes memory);
}
