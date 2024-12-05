message DeployNewticket{
    ticket: Ticket;
    owner: Address;
}
struct TicketData{
    ticket: Ticket;
    id: Int;
}
message ClaimWin{
    type: Int as uint3;
}
contract TicketContract with Parentable, OwnableTransferable {
    ticket: Ticket = Ticket{data: 0};
    parent: Address;
    id: Int as uint32;
    owner: Address;
    init(parent: Address, id: Int) {
        self.parent = parent;
        self.id = id;
        self.owner = newAddress(0,0);
    }
    // deploy ticket from parrent
    receive(m: DeployNewticket){
        self.requireParent();
        self.ticket = m.ticket;
        self.owner = m.owner;
    }
    get fun data(): TicketData{
        return TicketData{
            ticket: self.ticket,
            id: self.id
        };
    }

    receive(m: ClaimWin){
        self.requireOwner();
        self.forward(
            self.parent,
            ReceiveWin{fromTicketId:self.id,type: WinnerType{value: m.type}, ticket: self.ticket, excessTo: self.owner}.toCell(),
            true,
            null
        )
    }
    bounced(m: bounced<ReceiveWin>){
        self.forward(
            self.owner,
            "failed".asComment(),
            false,
            null
        );
    }


}