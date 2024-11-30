const WINNER_TYPE_CORNERS: Int = 1;
const WINNER_TYPE_CROSSING: Int = 2;
const WINNER_TYPE_FULL: Int = 3;
struct WinnerType{
    value: Int as uint3;

}
struct WinnersCounts {
    winnersCorners: Int as uint32;
    winnersCrossing: Int as uint32;
    winnersFull: Int as uint32;
}

struct Winners {
    items: map<Int as uint32, WinnerType>;
    winnersCounts: WinnersCounts = WinnersCounts{winnersCorners: 0, winnersCrossing: 0, winnersFull: 0};
}
struct NeedBarrels {
    corners: Int as uint7;
    crossing: Int as uint7;
    full: Int as uint7;
}
struct ExpectedWinners {
    // all numbers multiplied by 100_000
    corners: Int as uint32;
    crossing: Int as uint32;
    full: Int as uint32;
}
message ReceiveWin {
    fromTicketId: Int as uint32;
    type: WinnerType;
    ticket: Ticket;
}

trait Winnerable with DigitsTakerOut, TicketDeployable {
    registerUntil: Int;
    winners: Winners;
    lastDigitTakenOutDate: Int;
    digitsTakenOut: TookOutDigits;
    needBarrels: NeedBarrels;
    ticketsCount: Int;
    expectedWinners: ExpectedWinners;


    override inline fun requireNotEnoughWinners(type: Int){
        if(type >= WINNER_TYPE_CORNERS) {
            require(self.digitsTakenOut.count < self.needBarrels.corners, "Not enough corners winners");
        }
        if(type >= WINNER_TYPE_CROSSING) {
            require(self.digitsTakenOut.count < self.needBarrels.crossing, "Not enough crossing winners");
        }
        if(type >= WINNER_TYPE_FULL) {
            require(self.digitsTakenOut.count < self.needBarrels.full, "Not enough full winners");
        }
    }
    override inline fun initializeDigits(){
        if(self.needBarrels.full == 0){
            self.needBarrels = NeedBarrels{
                corners: needToTakeOutBarrels(4, self.ticketsCount, self.expectedWinners.corners),
                crossing: needToTakeOutBarrels(8, self.ticketsCount, self.expectedWinners.crossing),
                full: needToTakeOutBarrels(24, self.ticketsCount, self.expectedWinners.full)
            };
        }
    }
    receive(m: ReceiveWin){
        self.requireRegisterClosed();
        require(sender() == contractAddress(self.ticketAt(m.fromTicketId)), "Winnerable: sender is not an NFT");
        if(m.type.value == WINNER_TYPE_CORNERS){
            require(self.digitsTakenOut.count <= self.needBarrels.corners, "Not enough corners winners");
            require(m.ticket.isCrossingWins(self.digitsTakenOut), "Ticket is not corners winner");
        }
        else if(m.type.value == WINNER_TYPE_CROSSING){
            require(self.digitsTakenOut.count <= self.needBarrels.crossing, "Not enough crossing winners");
            require(m.ticket.isCrossingWins(self.digitsTakenOut), "Ticket is not crossing winner");
        }
        else if(m.type.value == WINNER_TYPE_FULL){
            require(self.digitsTakenOut.count <= self.needBarrels.full, "Not enough full winners");
            require(m.ticket.isWinner(self.digitsTakenOut), "Ticket is not full winner");
        }
        else {
            throw(1235);
        }
        let old: Int = 0;
        let q = self.winners.items.get(m.fromTicketId);
        if(q != null){
            old = q!!.value;
        }
        let new = (1<< m.type.value) | old;
        self.winners.items.set(m.fromTicketId, WinnerType{value: new});

    }
}