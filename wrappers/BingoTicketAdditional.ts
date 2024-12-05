import { TicketContract } from '../build/TonBingo/tact_TicketContract';
import { Address, ContractProvider } from '@ton/core';

type TicketData = number[][];

//@ts-ignore
export class BingoTicketAdditional extends TicketContract {
    static from(address: Address) {
        // @ts-ignore
        return new BingoTicketAdditional(address);
    }

    public async getRealData(provider: ContractProvider): Promise<TicketData> {
        const data = await this.getData(provider);
        let ans: number[][] = [];
        let g = data.ticket.data;

        for (let x = 0; x < 5; x++) {
            let row: number[] = [];
            for (let y = 0; y < 5; y++) {
                let digit = g & 0x7fn;
                row.push(Number(digit));
                g >>= 7n;
            }
            ans.push(row);
        }
        return ans;
    }
}
