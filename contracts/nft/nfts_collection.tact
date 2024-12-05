inline fun setImage(data: map<Int, ElString>, avatar: String): map<Int, ElString>{
     data.set(sha256("image_data"), ElString{ value: avatar});
    return data;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address?;
}
struct ElString{value: String;}


inline fun nftTextToCellAsDict(input: String): Cell {
    let dict: map<Int as uint32, Cell> = emptyMap();
    let curr: Slice = input.asSlice();
    let valid = true;
    let i = 0;
    while(valid){
        dict.set(i, curr.loadBits(curr.bits()).asCell());
        i += 1;
        valid = !curr.refsEmpty();
        if(valid){
            curr = curr.loadRef().asSlice();
        }
    }

    return beginCell()
    //1 - chunk dict
    .storeUint(1, 8)
    .storeBool(true)
    .storeRef(dict.asCell()!!)
    .asCell();

}
struct Backgrounds {
    images: map<Int, ElString>;
    length: Int;
}

inline fun nftTextToCell(input: String, storeAsSnake: Bool): Cell {
    return nftTextToCellAsDict(input);
}


fun buildData(content: map<Int, ElString>, asSnake: Bool): Cell {
    let ans: map<Int as uint256, Cell> = emptyMap();
    foreach(key, value in content){
        //
        ans.set(key, nftTextToCell(value.value, asSnake));
    }
    return beginCell().storeInt(0, 8).storeBool(true).storeRef(ans.asCell()!!).endCell()
    //    OnChainData{
    //        byte: 0,
    //        data: ans
    //    }.toCell();
}

trait NftsCollection{
    ticketsCount: Int;
    const CollectionName: String = "TON Bingo";
    const CollectionDescription: String = "TON Bingo NFTs";
    images: map<Int, ElString>;
    backgrounds: Backgrounds;
    const LogoURL: String = "https://raw.githubusercontent.com/imartemy1524/ton-bingo/refs/heads/master/images/logo.png";

    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: self.CollectionDescription});
        data = setImage(data, self.LogoURL);
        data.set( sha256("image"), ElString{ value: self.LogoURL});
        data.set(sha256("marketplace"), ElString{ value: "http://tonbingolottery.ton"});
        return CollectionData{
            next_item_index: self.ticketsCount,
            collection_content: buildData(data, true),
            owner_address: newAddress(0,0),
        };
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: TicketDataNft = TicketDataNft.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{value: content.buildNftName(index)});
        data = setImage(data, content.buildImage(index, self.backgrounds, self.images));
        data.set(sha256("description"), ElString{ value: content.buildDescription(index)});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data, true);
        return ans;
    }

}