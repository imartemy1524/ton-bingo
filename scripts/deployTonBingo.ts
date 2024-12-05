import { toNano } from '@ton/core';
import { TonBingo } from '../wrappers/TonBingo';
import { NetworkProvider } from '@ton/blueprint';
import { randomAddress } from '@ton/test-utils';

export async function run(provider: NetworkProvider) {
    const tonBingo = provider.open(
        await TonBingo.fromInit(provider.sender().address!, BigInt(Math.floor(+new Date() / 1000) + 3600), toNano('0.05'), {
            corners: 300_000n,
            $$type: 'ExpectedWinners',
            full: 50_000n,
            crossing: 100_000n
        }),
    );

    await tonBingo.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'DeployMaster',
            jetton: randomAddress(),
        },
    );

    await provider.waitForDeploy(tonBingo.address);

    console.log('Bingo address', await tonBingo.address);
}
