// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface StorageInterface {
  function append(uint8[] memory buffer) external;

  function getBytes() external view returns (bytes memory);

  function setName(string memory _name) external;
}
