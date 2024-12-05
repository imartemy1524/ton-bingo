import "./_structs.tact";
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address?;
    individual_content: Cell;
}

trait NftItem with Ownable, Parentable{
    owner: Address;
    parent: Address;
    id: Int;
    ticket: Ticket;
    virtual const ComputeFee: Int = ton("0.011");

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.ticket.data != 0,
            index: self.id,
            collection_address: self.parent,
            owner_address: self.owner,
            individual_content: self.getContent()
        };
    }
    inline fun getContent(): Cell{
        return TicketDataNft{ticket: self.ticket}.toCell();
    }


    receive(msg: GetStaticData){
        let ctx = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,  // (return msg amount except gas fees)
            bounce: true,
            body: ReportStaticData{ query_id: msg.query_id, index_id: self.id, collection: self.parent}.toCell()
        });
    }

    receive(msg: Transfer){
        self.requireOwner();
        require(self.ticket.data != 0, "NFT is not initialized");
        let ctx = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context

        self.owner = msg.new_owner;  // change current owner to the new_owner
        //f@cking work with comissions... IDK, how it works
        let msgValue: Int = self.msgValue(ctx.value);
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: ctx.sender,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        msgValue -= ctx.readForwardFee();
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: msgValue - msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: Excesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    inline fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = self.storageReserve - min(tonBalanceBeforeMsg, self.storageReserve);
        return value - (storageFee + self.ComputeFee);
    }

}