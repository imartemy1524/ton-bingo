import { beginCell, BitBuilder, BitReader, Builder, Cell, Dictionary, Slice } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { Backgrounds, ElString } from '../build/TonBingo/tact_TonBingo';
import fs from 'node:fs';
import { readFile } from 'node:fs/promises';
import { readFileSync } from 'fs';
//parsing onchain data in NFT
//reference: https://stackblitz.com/edit/ton-onchain-nft-parser?file=src%2Fmain.ts
//https://docs.ton.org/develop/dapps/asset-processing/metadata
interface ChunkDictValue {
    content: Buffer;
}

type IDataAttribute = {
    trait_type: string;
    value: string;
};

interface NFTDictValue {
    content: Buffer;
}

interface NftData {
    name?: string;
    description?: string;
    image?: string;
    image_data?: Buffer;
    marketplace?: string;

    attributes?: IDataAttribute[];
}

class NftOnChainDataParserClass {
    flattenSnakeCell(cell: Cell) {
        let c: Cell | null = cell;

        const bitResult = new BitBuilder(100000);
        while (c) {
            const cs = c.beginParse();
            if (cs.remainingBits === 0) {
                break;
            }

            const data = cs.loadBits(cs.remainingBits);
            bitResult.writeBits(data);
            c = c.refs && c.refs[0];
        }

        const endBits = bitResult.build();
        const reader = new BitReader(endBits);

        return reader.loadBuffer(reader.remaining / 8);
    }

    bufferToChunks(buff: Buffer, chunkSize: number) {
        const chunks: Buffer[] = [];
        while (buff.byteLength > 0) {
            chunks.push(buff.slice(0, chunkSize));
            // eslint-disable-next-line no-param-reassign
            buff = buff.slice(chunkSize);
        }
        return chunks;
    }

    makeSnakeCell(data: Buffer): Cell {
        const chunks = this.bufferToChunks(data, 127);

        if (chunks.length === 0) {
            return beginCell().endCell();
        }

        if (chunks.length === 1) {
            return beginCell().storeBuffer(chunks[0]).endCell();
        }

        let curCell = beginCell();

        for (let i = chunks.length - 1; i >= 0; i--) {
            const chunk = chunks[i];

            curCell.storeBuffer(chunk);

            if (i - 1 >= 0) {
                const nextCell = beginCell();
                nextCell.storeRef(curCell);
                curCell = nextCell;
            }
        }

        return curCell.endCell();
    }

    encodeOffChainContent(content: string) {
        let data = Buffer.from(content);
        const offChainPrefix = Buffer.from([1]);
        data = Buffer.concat([offChainPrefix, data]);
        return this.makeSnakeCell(data);
    }

    ChunkDictValueSerializer = {
        serialize(src: ChunkDictValue, builder: Builder) {},
        parse: (src: Slice): ChunkDictValue => {
            const snake = this.flattenSnakeCell(src.loadRef());
            return { content: snake };
        },
    };

    parseChunkDict(cell: Slice): Buffer {
        const dict = cell.loadDict(Dictionary.Keys.Uint(32), this.ChunkDictValueSerializer);

        let buf = Buffer.alloc(0);
        for (const [_, v] of dict) {
            buf = Buffer.concat([buf, v.content]);
        }
        return buf;
    }
}

export function decodeNftDataOnchain(data: Cell): NftData {
    const NftOnChainDataParser = new NftOnChainDataParserClass();
    const NFTDictValueSerializer = {
        serialize(src: NFTDictValue, builder: Builder) {},
        parse(src: Slice): NFTDictValue {
            const ref = src.loadRef().asSlice();

            const start = ref.loadUint(8);
            if (start === 0) {
                const snake = NftOnChainDataParser.flattenSnakeCell(ref.asCell());
                return { content: snake };
            }

            if (start === 1) {
                return { content: NftOnChainDataParser.parseChunkDict(ref) };
            }

            return { content: Buffer.from([]) };
        },
    };
    let slice = data.asSlice();

    slice.loadUint(8);
    const ans = slice.loadDict(Dictionary.Keys.Buffer(32), NFTDictValueSerializer);
    const ansMapped: Map<bigint, NFTDictValue> = new Map(
        Array.from(ans).map(([k, v]) => [BigInt('0x' + k.toString('hex')), v]),
    );
    const keys = new Map<bigint, string>(
        ['image', 'name', 'description', 'image', 'marketplace', 'image_data', 'attributes'].map((key) => [
            sha256(key),
            key,
        ]),
    );

    const realGoodObject: NftData = {};
    for (const [keyHash, valueBuffer] of ansMapped) {
        const realKey: string = keys.get(keyHash)!;
        if (!realKey) {
            console.warn('key not found', keyHash);
        }
        let value: Buffer | string = valueBuffer.content;
        if (realKey === 'attributes') {
            let v = value!.toString('utf-8');
            value = JSON.parse(v);
        } else if (realKey != 'image_data') {
            value = value!.toString('utf-8');
        }
        //@ts-ignore
        realGoodObject[realKey! as unknown as 'image'] = value!;
    }
    return realGoodObject;
}

export function sha256(s: string): bigint {
    return BigInt('0x' + sha256_sync(s).toString('hex'));
}

export function writeBuffer(src: Buffer, builder: Builder) {
    if (src.length > 0) {
        let bytes = Math.floor(builder.availableBits / 8);
        if (src.length > bytes) {
            let a = src.subarray(0, bytes);
            let t = src.subarray(bytes);
            builder = builder.storeBuffer(a);
            let bb = beginCell();
            writeBuffer(t, bb);
            builder = builder.storeRef(bb.endCell());
        } else {
            builder = builder.storeBuffer(src);
        }
    }
}

export async function generateImagesAndBackgrounds() {
    let images: Dictionary<bigint, ElString> = Dictionary.empty();
    await Promise.all(
        Array(99)
            .fill(0)
            .map(async (_, i) => {
                for (let i = 1; i <= 99; i++) {
                    const image = await readFile(`./images/${i}.webp`);
                    images.set(BigInt(i), { $$type: 'ElString', value: image.toString('base64') });
                }
            }),
    );

    const bgs: Dictionary<bigint, ElString> = Dictionary.empty();
    const backgrounds: Backgrounds = {
        $$type: 'Backgrounds',
        length: 123n,
        images: bgs,
    };
    for (let i = 1; i <= 1; i++) {
        const image = await readFile(`./backgrounds/${i}.webp`);
        bgs.set(BigInt(i), { $$type: 'ElString', value: 'data:image/webp;base64,' + image.toString('base64') });
    }
    return { images, backgrounds };
}
