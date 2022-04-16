// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {IStorage} from './interfaces/IStorage.sol';
import {Base64} from './libraries/Base64.sol';

// MAX number of assets: 65536
// MAX asset size: 16MB

contract Storage is IStorage {
    modifier onlyOwner() {
        require(_owner == msg.sender, 'msg.sender!=_owner');
        _;
    }

    modifier onlyInprogressAsset(uint16 _assetId) {
        require(progress[_assetId] < _assets[_assetId].length, 'progress>=bufferLength');
        _;
    }

    event AssetCreated(uint16 _assetId);

    address private _owner;
    uint16 private _assetCount;
    mapping(uint16 => uint256[]) private _assets;
    mapping(uint16 => uint24) private _bufferLengthsInBytes;
    mapping(uint16 => uint24) public progress;

    constructor() {
        _owner = msg.sender;
    }

    function createAsset(uint24 _bufferLengthInBytes) public override onlyOwner {
        _bufferLengthsInBytes[_assetCount] = _bufferLengthInBytes;
        if (_bufferLengthInBytes % 32 > 0) {
            _assets[_assetCount] = new uint256[]((_bufferLengthInBytes / 32) + 1);
        } else {
            _assets[_assetCount] = new uint256[]((_bufferLengthInBytes / 32));
        }
        emit AssetCreated(_assetCount++);
    }

    function appendAssetBuffer(uint16 _assetId, uint256[] memory _buffer) public override onlyOwner onlyInprogressAsset(_assetId) {
        for (uint256 i = 0; i < _buffer.length; i++) {
            _assets[_assetId][progress[_assetId] + i] = _buffer[i];
        }
        progress[_assetId] += uint24(_buffer.length);
    }

    function getAssetBytes(uint16 _assetId) public view override returns (bytes memory _bytes) {
        _bytes = new bytes(_bufferLengthsInBytes[_assetId]);
        for (uint256 i = 0; i < progress[_assetId]; i++) {
            uint256 num = _assets[_assetId][i];
            for (uint256 j = 0; num > 0 && j < 32 && (i * 32 + j) < _bufferLengthsInBytes[_assetId]; j++) {
                uint8 remainder = uint8(num % 0x100);
                _bytes[i * 32 + j] = bytes1(uint8(remainder));
                num = num / 0x100;
            }
        }
    }
}
