// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface RickRollInterface {
  function append(uint256[] memory buffer) external;
  function getRickRoll() external view returns (string memory);
  function setName(string memory _name) external;
}
