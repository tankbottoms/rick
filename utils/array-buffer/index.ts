export function bufferToArrayBuffer(buffer: Buffer) {
  return Array.from(buffer);
}

/**
 * @param Buffer buffer
 * @returns string[] hexStringArray
 */
export function bufferTo32ArrayBuffer(buffer: Buffer) {
  const arrayBuffer = Array.from(buffer);
  const uint256ArrayBuffer: string[] = [];

  for (let i = 0; i < arrayBuffer.length; i++) {
    if (uint256ArrayBuffer.length === 0 || uint256ArrayBuffer[uint256ArrayBuffer.length - 1].length >= 64) uint256ArrayBuffer.push('');
    uint256ArrayBuffer[uint256ArrayBuffer.length - 1] += (arrayBuffer[i] || 0).toString(16).padStart(2, '0');
  }

  for (let i = 0; i < uint256ArrayBuffer.length; i++) {
    uint256ArrayBuffer[i] = '0x' + uint256ArrayBuffer[i].padEnd(64, '0');
  }
  return uint256ArrayBuffer;
}
