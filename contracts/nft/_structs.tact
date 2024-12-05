
struct TicketDataNft {
    ticket: Ticket;
}

extends inline fun buildNftName(self: TicketDataNft, index: Int): String{
    return beginString().concat("Ticket #").concat(index.toString()).toString();
}


extends inline fun buildDescription(self: TicketDataNft, index: Int): String {
    return "TON Bingo ticket, which can win prices in BINGO lottery!";
}
extends inline fun buildAttributesString(self: TicketDataNft): String {
    //TODO
    return "[]";
}
extends inline fun buildImage(self: TicketDataNft, index: Int, backgrounds: Backgrounds, images: map<Int, ElString>): String{
    let bg = backgrounds.images.get(index % backgrounds.length)!!.value;
    return generateSvg(bg, self.ticket, images)
}