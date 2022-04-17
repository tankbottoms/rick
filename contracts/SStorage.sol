// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '@0xsequence/sstore2/contracts/SSTORE2Map.sol';

contract SStorage {
    modifier onlyOwner() {
        require(_owner == msg.sender, 'msg.sender!=_owner');
        _;
    }

    event AssetCreated(bytes32 _assetId);

    address private _owner;
    mapping(uint256 => bytes32) private _assetIdKeyMap;
    uint256 private _assetCount;

    constructor() {
        _owner = msg.sender;
    }

    function createAsset(uint256 _assetId, bytes32 _assetKey, bytes32[] memory _content) public {
        SSTORE2Map.write(_assetKey, abi.encode(_content));
        _assetIdKeyMap[_assetId] = _assetKey;
        _assetCount++;
        emit AssetCreated(_assetKey);
    }

    function getAssetForKey(bytes32 _assetKey) public view returns (bytes32[] memory) {
        return abi.decode(SSTORE2Map.read(_assetKey), (bytes32[]));
    }

    function getAssetForId(uint256 _assetId) public view returns (bytes32[] memory) {
        return abi.decode(SSTORE2Map.read(_assetIdKeyMap[_assetId]), (bytes32[]));
    }

    function getAssetKeyForId(uint256 _assetId) public view returns (bytes32) {
        return _assetIdKeyMap[_assetId];
    }
}
