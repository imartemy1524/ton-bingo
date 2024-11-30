import { Blockchain, printTransactionFees, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Cell, toNano } from '@ton/core';
import { TonBingo } from '../wrappers/TonBingo';
import '@ton/test-utils';
import { randomAddress } from '@ton/test-utils';
import { TicketContract } from '../build/TonBingo/tact_TicketContract';
import { BingoTicketAdditional } from '../wrappers/BingoTicketAdditional';

function equalsData(data: number[][], dataBin: Cell) {
    let cell = dataBin.beginParse();
    let x = 0;
    let y = 0;
    while (x < 5) {
        let digit =BigInt( data[x][y]);
        // cell = cell.loadRef().beginParse();
        const digitFromCell = cell.loadUintBig(7);
        expect(digit).toBeLessThan(100n);
        expect(digit).toBeGreaterThan(0n);
        expect(digit).toEqual(digitFromCell);
        if (++y === 5) {
            y = 0;
            x++;
        }
    }
    return true;
}

describe('TonBingo', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let tonBingo: SandboxContract<TonBingo>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        blockchain.now = 1;
        deployer = await blockchain.treasury('deployer');

        tonBingo = blockchain.openContract(await TonBingo.fromInit(deployer.address, 1000n, toNano('0.2')));

        const deployResult = await tonBingo.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'DeployMaster',
                jetton: randomAddress(),
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: tonBingo.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        const { amount, ticketsCount, registerUntil } = await tonBingo.getData();
        expect(amount).toBe(toNano('0.2'));
        expect(ticketsCount).toBe(0n);
        expect(registerUntil).toBe(1000n);
    });

    it('should mint new ticket', async () => {
        const { ticketsCount: prevId } = await tonBingo.getData();
        const { transactions } = await tonBingo.send(deployer.getSender(), { value: toNano('0.2') }, 'get');
        printTransactionFees(transactions);
        const { ticketsCount: nextId } = await tonBingo.getData();
        expect(nextId).toBe(prevId + 1n);
        const newTicket = await tonBingo.getGetNftAddressByIndex(nextId);
        expect(transactions).toHaveTransaction({
            to: newTicket,
            deploy: true,
            success: true,
        });
        // now lets verify, that ticket's data is valid

        const data: number[][] = await blockchain.openContract(BingoTicketAdditional.from(newTicket)).getRealData();
        for(let i = 0; i < 5; i++) {
            for(let j = 0; j < 5; j++) {
                expect(data[i][j]).toBeLessThan(100);
                expect(data[i][j]).toBeGreaterThan(0);
            }
        }
    });
});
