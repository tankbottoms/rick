import fs from 'fs';
import { resolve } from 'path';
import { bufferTo32ArrayBuffer } from './array-buffer';

export function chunkAsset(path: string): {length: number, parts: string[][]} {
    const CHUNK_SIZE = Math.floor((1024 * 8) / 32); // 24KB

    const buffer = fs.readFileSync(resolve(__dirname, '..', path));
    const arrayBuffer32 = bufferTo32ArrayBuffer(buffer);

    const parts: string[][] = [];
    for (let i = 0; i < arrayBuffer32.length; i += CHUNK_SIZE) {
        parts.push(arrayBuffer32.slice(i, i + CHUNK_SIZE));
    }

    return { length: buffer.length, parts };
}
