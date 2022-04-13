// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface StorageInterface {
  function set(string memory key, string memory value) external;

  function get(string memory key) external view returns (string memory);
}
