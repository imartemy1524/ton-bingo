


trait TicketDeployable{
    inline fun ticketAt(index: Int): StateInit{
        return initOf TicketContract(myAddress(), index);
    }
    inline fun deployTicket(ticket: Ticket, id: Int){
        let t = self.ticketAt(id);
        send(SendParameters{
            to: contractAddress(t),
            value: ton("0.02"),
            bounce: false,
            body: DeployNewticket{ticket: ticket}.toCell(),
            code: t.code,
            data: t.data,
            mode: SendBounceIfActionFail
        });
    }

    get fun get_nft_address_by_index(index: Int): Address{
        let t = self.ticketAt(index);
        return contractAddress(t);
    }
}