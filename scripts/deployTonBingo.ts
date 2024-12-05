import { toNano } from '@ton/core';
import { TonBingo } from '../wrappers/TonBingo';
import { NetworkProvider } from '@ton/blueprint';
import { randomAddress } from '@ton/test-utils';
import { generateImagesAndBackgrounds } from '../tests/__helpers';

export async function run(provider: NetworkProvider) {
    const { images, backgrounds } = await generateImagesAndBackgrounds();

    const tonBingo = provider.open(
        await TonBingo.fromInit(
            provider.sender().address!,
            BigInt(Math.floor(+new Date() / 1000) + 3600 * 24 * 7),
            toNano('0.05'),
            {
                corners: 300_000n,
                $$type: 'ExpectedWinners',
                full: 50_000n,
                crossing: 100_000n,
            },
            images,
            backgrounds,
        ),
    );
    await new Promise((resolve) => setTimeout(resolve, 4000));
    await tonBingo.send(
        provider.sender(),
        {
            value: toNano('0.1'),
        },
        {
            $$type: 'DeployMaster',
            jetton: randomAddress(),
        },
    );
    await new Promise((resolve) => setTimeout(resolve, 4000));
    await provider.waitForDeploy(tonBingo.address);

    console.log('Bingo address', tonBingo.address);
}
