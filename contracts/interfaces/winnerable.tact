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
    winnersCounts: WinnersCounts = WinnersCounts{ winnersCorners: 0, winnersCrossing: 0, winnersFull: 0};
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
    excessTo: Address;
}
struct Decimal {
    numerator: Int as uint16;
    denominator: Int as uint16;
}
struct PricesDistributionCoef {
    corners: Decimal;
    crossing: Decimal;
    full: Decimal;
}

trait Winnerable with DigitsTakerOut, TicketDeployable, Ownable {
    registerUntil: Int;
    winners: Winners;
    lastDigitTakenOutDate: Int;
    digitsTakenOut: TookOutDigits;
    needBarrels: NeedBarrels;
    ticketsCount: Int;
    expectedWinners: ExpectedWinners;
    pricesDistribution: PricesDistributionCoef;
    rewardsSent: Bool;
    owner: Address;

    override inline fun requireNotEnoughWinners(type: Int){
        if(type == WINNER_TYPE_FULL) {
            require(self.digitsTakenOut.count < self.needBarrels.full, "Not enough full winners");
        }
    }
    override inline fun initializeDigits(){
        if(self.needBarrels.full == 1){
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
            require(m.ticket.isWinnerCorners(self.digitsTakenOut), "Ticket is not corners winner");
            self.winners.winnersCounts.winnersCorners += 1;
        }
        else if(m.type.value == WINNER_TYPE_CROSSING){
            require(self.digitsTakenOut.count <= self.needBarrels.crossing, "Not enough crossing winners");
            require(m.ticket.isCrossingWins(self.digitsTakenOut), "Ticket is not crossing winner");
            self.winners.winnersCounts.winnersCrossing += 1;
        }
        else if(m.type.value == WINNER_TYPE_FULL){
            require(self.digitsTakenOut.count <= self.needBarrels.full, "Not enough full winners");
            require(m.ticket.isWinner(self.digitsTakenOut), "Ticket is not full winner");
            self.winners.winnersCounts.winnersFull += 1;
        }
        else {
            throw(1235);
        }
        let old: Int = 0;
        let q = self.winners.items.get(m.fromTicketId);
        if(q != null){
            old = q!!.value;
        }
        require((old & (1 << m.type.value)) == 0, "Already a winner");
        let new = (1 << m.type.value) | old;
        self.winners.items.set(m.fromTicketId, WinnerType{
        value: new});
        self.forward(m.excessTo, "Congratulations🥳".asComment(), false, null);
    }

    external("send_rewards"){
        self.requireRegisterClosed();
        require(!self.rewardsSent, "Rewards already sent");
        require(self.digitsTakenOut.count >= self.needBarrels.full, "Not enough full winners");
        require(self.lastDigitTakenOutDate + 86400 > now(), "Not enough time passed");
        let amount = myBalance();
        let winners = self.winners.items;
        acceptMessage();
        foreach(ticketIndex, winType in winners){
            let ticket = self.ticketAt(ticketIndex);
            if(winType.value & (1 << WINNER_TYPE_CORNERS)) != 0 {
                let reward = (self.pricesDistribution.corners.numerator * amount) / (self.pricesDistribution.corners.denominator * self.winners.winnersCounts.winnersCorners);
                send(SendParameters{
                    to: contractAddress(ticket),
                    value: reward,
                    bounce: false,
                    mode: 0,
                    body: "corners winner reward".asComment()
                });
            }
            if(winType.value & (1 << WINNER_TYPE_CROSSING)) != 0 {
                let reward = (self.pricesDistribution.crossing.numerator * amount) / (self.pricesDistribution.crossing.denominator * self.winners.winnersCounts.winnersCrossing);
                send(SendParameters{
                    to: contractAddress(ticket),
                    value: reward,
                    bounce: false,
                    mode: 0,
                    body: "crossing winner reward".asComment()
                });
            }
            if(winType.value & (1 << WINNER_TYPE_FULL)) != 0 {
                let reward = (self.pricesDistribution.full.numerator * amount) / (self.pricesDistribution.full.denominator * self.winners.winnersCounts.winnersFull);
                send(SendParameters{
                    to: contractAddress(ticket),
                    value: reward,
                    bounce: false,
                    mode: 0,
                    body: "full winner reward".asComment()
                });
            }
        }
        self.rewardsSent = true;
    }
    external("system_profit"){
        require(self.rewardsSent, "Rewards not sent yet");
        require(myBalance() > ton("0.02"), "No profit");
        acceptMessage();
        send(SendParameters{
            to: self.owner,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance,
            body: "system profit".asComment()
        });
    }


    get fun isWinner(type: Int, ticket: Ticket): Bool{
        self.requireRegisterClosed();
        return type == WINNER_TYPE_FULL? ticket.isWinner(self.digitsTakenOut):
            type == WINNER_TYPE_CORNERS? ticket.isWinnerCorners(self.digitsTakenOut):
            type == WINNER_TYPE_CROSSING? ticket.isCrossingWins(self.digitsTakenOut):
            false;

    }

}