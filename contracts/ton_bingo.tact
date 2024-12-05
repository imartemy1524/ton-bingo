import "@stdlib/deploy";
import "@stdlib/ownable";
import "./structs/ticket.tact";
import "./interfaces/parentable.tact";
import "./interfaces/ticket_deployable.tact";
import "./interfaces/registrable.tact";
import "./interfaces/digits_taker.tact";
import "./ticket.tact";
import "./interfaces/winnerable.tact";
import "./nft/nft_item.tact";
import "./nft/image_generator.tact";
import "./nft/nfts_collection.tact";
struct BingoData {
    ticketsCount: Int;
    registerUntil: Int;
    amount: Int;
    winners: Winners;
    lastDigitTakenOutDate: Int;
    needBarrels: NeedBarrels;
}
message DeployMaster {
    jetton: Address;
}

contract TonBingo with Registrable, TicketDeployable, OwnableTransferable, Winnerable, NftsCollection {
    registerUntil: Int as uint64;
    amount: Int as coins;
    owner: Address;
    jetton: Address;
    ticketsCount: Int as uint32 = 0;
    digitsTakenOut: TookOutDigits = TookOutDigits{data: 0, count: 0};
    lastDigitTakenOutDate: Int as uint64 = 0;
    winners: Winners = Winners{items: emptyMap()};
    needBarrels: NeedBarrels = NeedBarrels{corners: 1, crossing: 1, full: 1};
    expectedWinners: ExpectedWinners;
    pricesDistribution: PricesDistributionCoef = PricesDistributionCoef{
        corners: Decimal{numerator: 1, denominator: 10},
        crossing: Decimal{numerator: 3, denominator: 10},
        full: Decimal{numerator: 5, denominator: 10},
    };
    rewardsSent: Bool = false;
    images: map<Int, ElString>;

    init(owner: Address, registerUntil: Int, amount: Int, expectedWinners: ExpectedWinners, images: map<Int, ElString>) {
        self.registerUntil = registerUntil;
        self.amount = amount;
        self.owner = owner;
        self.jetton = newAddress(0, 0);
        self.expectedWinners = expectedWinners;
        self.images = images;
    }
    // deploy contract
    receive(m: DeployMaster){
        self.jetton = m.jetton;
    }
    receive("get") {
        self.requireCanRegister();
        require(context().value >= self.amount, "Not enough money");
        let ticket = randomTicket();
        self.ticketsCount += 1;
        self.deployTicket(ticket, self.ticketsCount, sender());
    }
    get fun data(): BingoData {
        return BingoData {
            ticketsCount: self.ticketsCount,
            registerUntil: self.registerUntil,
            amount: self.amount,
            winners: self.winners,
            lastDigitTakenOutDate: self.lastDigitTakenOutDate,
            needBarrels: self.needBarrels
        };
    }



}
