import { beginCell, Cell, Dictionary } from '@ton/core';
import * as fs from 'node:fs';

const s = beginCell().storeDict(ans, Dictionary.Keys.Int(32), Dictionary.Values.Cell()).endCell().toBoc();
console.log(s.toString('base64'));
