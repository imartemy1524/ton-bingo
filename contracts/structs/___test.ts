/**
 * @param squares - length of squares which needs to match
 * @param users - count of users, who will play
 * @param winners100_000 - predicted number of winners, multiplied by 100'000
 * @constructor
 */
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
    console.log(`Nominator is ${nominator}, denominator is ${denominator} for ${squares} squares`);

    for (let takenCount = squares + 1n; takenCount <= 99n; takenCount++) {
        nominator /= takenCount - squares;
        nominator *= takenCount;
        if (nominator * users * 100000n >= winners100_000 * denominator) return takenCount;
    }
    throw new Error('No solution');
}

console.log('For 4 squares, 5000 users and one wants 6 winners', needToTakeOut(4n, 5000n, 6n * 100000n));
console.log("For 8 squares, 5000 users and one wants 1 winners", needToTakeOut(8n, 5000n, 100000n));
// for taking 63 squares randombly from given 24, the chances are 1%
console.log("For 24 squares, 5000 users and one wants 0.01 winners", needToTakeOut(24n, 5000n, 1000n));
