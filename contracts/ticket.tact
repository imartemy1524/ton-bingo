message DeployNewticket{
    ticket: Ticket;
}

contract TicketContract with Parentable {
    ticket: Ticket = Ticket{data: 0};
    parent: Address;
    id: Int as uint32;
    init(parent: Address, id: Int) {
        self.parent = parent;
        self.id = id;
    }
    // deploy ticket from parrent
    receive(m: DeployNewticket){
        self.requireParent();
        self.ticket = m.ticket;
    }
    get fun data(): Ticket{
        return self.ticket;
    }




}