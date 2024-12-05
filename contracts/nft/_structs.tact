
struct TicketDataNft {
    ticket: Ticket;
}

extends inline fun buildNftName(self: TicketDataNft, index: Int): String{
    return beginString().concat("Ticket #").concat(index.toString()).toString();
}

extends inline fun buildImage(self: TicketDataNft, index: Int, image: String): String{
    return generateSvg(image, self.ticket)
}
extends inline fun buildDescription(self: TicketDataNft, index: Int): String {
    return "TON Bingo ticket, which can win prices in BINGO lottery!";
}
extends inline fun buildAttributesString(self: TicketDataNft): String {
    //TODO
    return "[]";
}
