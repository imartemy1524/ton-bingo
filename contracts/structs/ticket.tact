struct TookOutDigits {
    // uint100 - for 100 digits from 1 to 99
    data: Int as uint100;
    count: Int as uint7;
}

struct Ticket{
    // uint175 - 7 * 25
    data: Int as uint175;
}

// TODO: carefully check this function logic
// returns first index of (index zero bit) from right to left
extends inline fun digitAtIndex(self: TookOutDigits, index: Int): Int{
    let i = 1;
    while(index >= 0){
        if(self.data & i) == 0{
            index -= 1;
        }
        i = i << 1;
    }
    return log2(i) - 1;
}

extends inline fun isWinnerCorners(self: Ticket, digits: TookOutDigits): Bool{
    let topLeftCorner = self.numberAt(0, 0);
    let topRightCorner = self.numberAt(4, 0);
    let bottomLeftCorner = self.numberAt(0, 4);
    let bottomRightCorner = self.numberAt(4, 4);
    return digits.isDigitTookOut(topLeftCorner) && digits.isDigitTookOut(topRightCorner) && digits.isDigitTookOut(bottomLeftCorner) && digits.isDigitTookOut(bottomRightCorner);
}
extends inline fun isCrossingWins(self: Ticket, digits: TookOutDigits): Bool{
    // check (2, 0), (2, 1), (2, 3), (2, 4), (0, 2), (1, 2), (3, 2), (4, 2)
    let a = self.numberAt(2, 0);
    let b = self.numberAt(2, 1);
    let c = self.numberAt(2, 3);
    let d = self.numberAt(2, 4);
    let e = self.numberAt(0, 2);
    let f = self.numberAt(1, 2);
    let g = self.numberAt(3, 2);
    let h = self.numberAt(4, 2);
    return digits.isDigitTookOut(a) && digits.isDigitTookOut(b) && digits.isDigitTookOut(c) && digits.isDigitTookOut(d) && digits.isDigitTookOut(e) && digits.isDigitTookOut(f) && digits.isDigitTookOut(g) && digits.isDigitTookOut(h);
}

extends inline fun isWinner(self: Ticket, digits: TookOutDigits): Bool{
    let x = 0;
    repeat(5){
        let y = 0;
        repeat(5){
            if(x != 2 && y != 2){
                let number = self.numberAt(x, y);
                if !digits.isDigitTookOut(number){
                    return false;
                }
            }
            y += 1;
        }
        x += 1;
    }
    return true;
}

extends inline fun isDigitTookOut(self: TookOutDigits, digit: Int): Bool {
    return (self.data & (1 << digit)) != 0;
}

extends inline fun numberAt(self: Ticket, x: Int, y: Int): Int {
    let index = y * 5 + x;
    // read 7 bits at index
    let shift = index * 7;
    // read 7 bits at index
    // 0x7F = 0111 1111
    let number = (self.data >> shift) & 0x7F;
    return number;
}

inline fun randomTicket(): Ticket{
    nativePrepareRandom();

    let ans = 0;
    repeat(25){
        ans = ans << 7;
        let number = (nativeRandom() % 99) + 1;
        ans = ans + number;
    }
    return Ticket{
    data: ans};
}

// function, which returns how many barrels should be taken out to have at average winners100_000 winners
// squares - count of squares in ticket to be "filled"
// users - count of users in game
// winners100_000 - expected number of users, multiplied by 100_000

// (in theory) it even doesn't overflow uint256 for normal values
fun needToTakeOutBarrels(squares: Int, users: Int, winners100_000: Int): Int{
    // compute 99*98*...*(99-squares)
    // TODO: precompute this
    let nominator = 1;
    // nominator / denominator * users >= winners
    let denominator = 1;

    if(squares == 4){
        nominator = 24;
        denominator = 90345024;
    }
    else if(squares == 8){
        nominator = 40320;
        denominator = 6902818786321920;
    }
    else if(squares == 24){
        nominator = 620448401733239439360000;
        denominator = 37617673321873894319687391903177156706959360000;
    }
    else {throw(1234);}
//for (let takenCount = squares + 1n; takenCount <= 99n; takenCount++) {
//nominator /= takenCount - squares;
//nominator *= takenCount;
//if (nominator * users * 100000n >= winners100_000 * denominator) return takenCount;
//}
    let takenCount = squares + 1;
    while(takenCount <= 99){
        nominator /= (takenCount - squares);
        nominator *= takenCount;
        if(nominator * users * 100000 >= winners100_000 * denominator){
            return takenCount;
        }
        takenCount += 1;
    }
    throw(1234);
}
