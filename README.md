# TON Bingo

This project contains implementation of a Bingo game on TON blockchain.

Each ticket is issued as an NFT, each ticket can be bought through the smart contract, the smart contract calculates needed barrels to be taken out to get `N` winners depends on the number of players using probability theory, and after the game ends users automatically receives the prizes.

## Project structure

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

## How to use

### Build

`npx blueprint build` or `yarn blueprint build`

### Test

`npx blueprint test` or `yarn blueprint test`

### Deploy or run another script

`npx blueprint run` or `yarn blueprint run`

### Add a new contract

`npx blueprint create ContractName` or `yarn blueprint create ContractName`
