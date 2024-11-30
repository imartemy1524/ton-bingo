trait Parentable{
    parent: Address;

    inline fun requireParent(){
        require(sender() == self.parent, "Parentable: sender is not parent");
    }
    inline fun requireNotParent(){
        require(sender() != self.parent, "Parentable: sender is parent");
    }
}