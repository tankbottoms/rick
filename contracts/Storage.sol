// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './interfaces/IStorage.sol';
import '@0xsequence/sstore2/contracts/SSTORE2Map.sol';

error ERR_CHUNK_SIZE_LIMIT();
error ERR_ASSET_EXISTS();
error ERR_ASSET_MISSING();

contract Storage is IStorage {
    uint32 private constant CHUNK_SIZE = 24 * 1024;

    modifier onlyOwner() {
        require(_owner == msg.sender, 'msg.sender!=_owner');
        _;
    }

    struct Attr {
        uint32 _type;
        bytes32[] _value;
    }

    struct Asset {
        uint64 _assetId;
        bytes32[] _nodes;
        uint64 _byteSize;
        mapping(string => Attr) _attrs;
        // TODO: consider, bool _complete;
    }

    // TODO: consider name -> id map
    // TODO: consider auto-increment on assetid

    event AssetCreated(bytes32 _assetId);

    address private _owner;
    mapping(uint64 => Asset) private _assetList;
    uint64 private _assetCount;

    constructor() {
        _owner = msg.sender;
    }

    function createAsset(
        uint64 _assetId,
        bytes32 _assetKey,
        bytes32[] memory _content,
        uint64 fileSizeInBytes
    ) public override onlyOwner {
        if (_content.length > CHUNK_SIZE / 32) {
            revert ERR_CHUNK_SIZE_LIMIT();
        }
        if (_assetList[_assetId]._assetId != 0) {
            revert ERR_ASSET_EXISTS();
        }

        SSTORE2Map.write(_assetKey, abi.encode(_content));

        _assetList[_assetId]._assetId = _assetId;
        _assetList[_assetId]._nodes.push(_assetKey);
        _assetList[_assetId]._byteSize = uint64(fileSizeInBytes);

        _assetCount++;
        emit AssetCreated(_assetKey);
    }

    function appendAssetContent(
        uint64 _assetId,
        bytes32 _assetKey,
        bytes32[] calldata _content
    ) public override onlyOwner {
        if (_content.length > CHUNK_SIZE / 32) {
            revert ERR_CHUNK_SIZE_LIMIT();
        }
        if (_assetList[_assetId]._assetId == 0 && _assetList[_assetId]._byteSize == 0) {
            revert ERR_ASSET_MISSING();
        }

        SSTORE2Map.write(_assetKey, abi.encode(_content));

        _assetList[_assetId]._nodes.push(_assetKey);
    }

    function setAssetAttribute(
        uint64 _assetId,
        string calldata _attrName,
        uint32 _attrType,
        bytes32[] calldata _value
    ) public override onlyOwner {
        // reserved:
        // uint32 _type;
        // string _name;
        // uint64 _timestamp;
    }

    function getAssetContentForId(uint64 _assetId) public view override returns (bytes memory _content) {
        _content = new bytes(_assetList[_assetId]._byteSize);
        uint64 partCount = uint64(_assetList[_assetId]._nodes.length);

        for (uint64 i = 0; i < partCount; i++) {
            bytes32[] memory partContent = getContentForKey(_assetList[_assetId]._nodes[i]);

            for (uint16 j = 0; j < partContent.length; j++) {
                uint64 offset = (i * CHUNK_SIZE) + (j * 32);
                bytes32 slice = partContent[j];

                for (uint16 k = 0; (offset + k < _assetList[_assetId]._byteSize) && k < 32; k++) {
                    _content[offset + k] = slice[k];
                }
            }
        }
    }

    function getAssetKeysForId(uint64 _assetId) public view override returns (bytes32[] memory) {
        return _assetList[_assetId]._nodes;
    }

    function getContentForKey(bytes32 _contentKey) public view override returns (bytes32[] memory) {
        return abi.decode(SSTORE2Map.read(_contentKey), (bytes32[]));
    }

    function getAssetSize(uint64 _assetId) public view override returns (uint64) {
        return _assetList[_assetId]._byteSize;
    }

    function getAssetInfoAttribute(uint64 _assetId, string calldata _attr) public view override returns (bytes memory) {
        return abi.encode(_assetList[_assetId]._attrs[_attr]);
    }
}
