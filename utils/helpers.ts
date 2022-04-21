import fs from 'fs';
import { resolve } from 'path';
import pako from 'pako';

import { bufferTo32ArrayBuffer } from './array-buffer';

const CHUNK_SIZE = Math.floor((1024 * 8) / 32); // 24KB

export function chunkDeflate(path: string): { length: number, parts: string[][], inflatedSize: number } {
    const buffer = fs.readFileSync(resolve(__dirname, '..', path));
    const compressed = pako.deflateRaw(buffer, { level: 9 });

    return { ...chunkBuffer(compressed), inflatedSize: buffer.length };
}

export function chunkAsset(path: string): { length: number, parts: string[][] } {
    const buffer = fs.readFileSync(resolve(__dirname, '..', path));

    return chunkBuffer(buffer);
}

function chunkBuffer(buffer: Buffer) {
    const arrayBuffer32 = bufferTo32ArrayBuffer(buffer);

    const parts: string[][] = [];
    for (let i = 0; i < arrayBuffer32.length; i += CHUNK_SIZE) {
        parts.push(arrayBuffer32.slice(i, i + CHUNK_SIZE));
    }

    return { length: buffer.length, parts };
}

export function chunkString(value: string): string[] {
    const buffer = Buffer.from(value);
    const arrayBuffer32 = bufferTo32ArrayBuffer(buffer);

    return arrayBuffer32;
}

export function reconstituteString(bytes: string[]) {
    let buffer = Buffer.from('');

    for (const part of bytes) {
        buffer = Buffer.concat([buffer, Buffer.from(part.slice(2), 'hex')]);
    }

    return buffer.toString('utf8').replace(/\0/g, '');
}

export function smallIntToBytes32(value: number): string {
    return '0x' + ('0000000000000000000000000000000000000000000000000000000000000000' + (value).toString(16)).slice(-64);
}
