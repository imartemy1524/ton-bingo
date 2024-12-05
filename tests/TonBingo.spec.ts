import { Blockchain, printTransactionFees, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, Dictionary, OpenedContract, toNano } from '@ton/core';
import { ElString, Ticket, TonBingo } from '../wrappers/TonBingo';
import '@ton/test-utils';
import { randomAddress } from '@ton/test-utils';
import { TicketContract } from '../build/TonBingo/tact_TicketContract';
import { BingoTicketAdditional } from '../wrappers/BingoTicketAdditional';
import { decodeNftDataOnchain } from './__helpers';
import * as fs from 'node:fs';

function needToTakeOut(squares: bigint, users: bigint, winners100_000: bigint) {
    // compute 99*98*...*(99-squares)
    // TODO: precompute this
    let nominator = 1n;
    // nominator / denominator * users >= winners
    let denominator = 1n;
    for (let i = 0n; i < squares; i++) {
        denominator *= 99n - i;
        nominator *= i + 1n;
    }
    for (let takenCount = squares + 1n; takenCount <= 99n; takenCount++) {
        nominator /= takenCount - squares;
        nominator *= takenCount;
        if (nominator * users * 100000n >= winners100_000 * denominator) return takenCount;
    }
    throw new Error('No solution');
}

function equalsData(data: number[][], dataBin: Cell) {
    let cell = dataBin.beginParse();
    let x = 0;
    let y = 0;
    while (x < 5) {
        let digit = BigInt(data[x][y]);
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
        let images: Dictionary<bigint, ElString> = Dictionary.empty();

        for (let i = 1; i <= 99; i++) {
            const image = fs.readFileSync(`./images/${i}.png`);
            images.set(BigInt(i), { $$type: 'ElString', value:  image.toString('base64') });
        }

        blockchain = await Blockchain.create();
        blockchain.now = 1;
        deployer = await blockchain.treasury('deployer');

        tonBingo = blockchain.openContract(
            await TonBingo.fromInit(deployer.address, 1000n, toNano('0.2'), {
                $$type: 'ExpectedWinners',
                // 4 winners (400%)
                corners: 100_000n * 4n,
                // one winner (100%)
                crossing: 100_000n,
                // 30%
                full: 30_000n,
            }, images),
        );

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
        const q = new Set(data.flat());
        expect(q.size).toBe(25);
        for (let i = 0; i < 5; i++) {
            for (let j = 0; j < 5; j++) {
                expect(data[i][j]).toBeLessThan(100);
                expect(data[i][j]).toBeGreaterThan(0);
            }
        }
    });

    it('tickets should win', async () => {
        const count = 100;
        let tickets: SandboxContract<BingoTicketAdditional>[] = [];
        for (let i = 0; i < count; i++) {
            const addr = await tonBingo.getGetNftAddressByIndex(BigInt(i + 1));
            tickets.push(blockchain.openContract(await BingoTicketAdditional.from(addr)));
        }
        await Promise.all(tickets.map(() => tonBingo.send(deployer.getSender(), { value: toNano('0.2') }, 'get')));
        for (const t of tickets) {
            await t.getData();
        }

        blockchain.now = 1001;
        await tonBingo.sendExternal('take');
        const { needBarrels } = await tonBingo.getData();
        expect(needBarrels.corners).toEqual(needToTakeOut(4n, BigInt(count), 100_000n * 4n));
        expect(needBarrels.crossing).toEqual(needToTakeOut(8n, BigInt(count), 100_000n));
        expect(needBarrels.full).toEqual(needToTakeOut(24n, BigInt(count), 30_000n));
        for (let i = 1n; i < needBarrels.corners; i++) {
            blockchain.now += 100;
            await tonBingo.sendExternal('take');
        }
        const winnerTickets = await Promise.all(
            tickets.map(async (ticket) => {
                const data = await ticket.getData();
                const isWinner = await tonBingo.getIsWinner(1n, data.ticket);
                if (isWinner) return ticket;
                return null;
            }),
        ).then((e) => e.filter((e) => e));
        for (const winner of winnerTickets) {
            const { transactions } = await winner!.send(
                deployer.getSender(),
                {
                    value: toNano('0.1'),
                },
                {
                    $$type: 'ClaimWin',
                    type: 1n,
                },
            );
            printTransactionFees(transactions);
            expect(transactions).toHaveTransaction({
                body: beginCell().storeUint(0, 32).storeStringTail('Congratulations🥳').endCell(),
            });
        }
    });
    it('ticket nft data should be valid', async () => {
        await tonBingo.send(deployer.getSender(), { value: toNano('0.2') }, 'get');
        const addr = await tonBingo.getGetNftAddressByIndex(BigInt(1));
        const ticket = blockchain.openContract(await BingoTicketAdditional.from(addr));
        const { individual_content, index } = await ticket.getGetNftData();
        const realContent = await tonBingo.getGetNftContent(index, individual_content);
        const onchainDataNFT = decodeNftDataOnchain(realContent);
        const SVG = onchainDataNFT.image_data!.toString('utf-8');
        // write svg to ./test.jpg
        fs.writeFileSync('./out.svg', SVG, 'utf8');
    });
});
