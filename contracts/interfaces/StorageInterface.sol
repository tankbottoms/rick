// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface StorageInterface {
  function set(bytes memory _text) external;

  function get() external view returns (bytes memory);
}
