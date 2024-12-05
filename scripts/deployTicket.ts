import { Address, toNano } from '@ton/core';
import { TonBingo } from '../wrappers/TonBingo';
import { NetworkProvider, sleep } from '@ton/blueprint';

export async function run(provider: NetworkProvider, args: string[]) {
    const ui = provider.ui();

    const address = Address.parse(args.length > 0 ? args[0] : await ui.input('TonBingo address'));

    if (!(await provider.isContractDeployed(address))) {
        ui.write(`Error: Contract at address ${address} is not deployed!`);
        return;
    }

    const tonBingo = provider.open(TonBingo.fromAddress(address));

    await tonBingo.send(provider.sender(), {value: toNano('0.05')}, 'get')
}
