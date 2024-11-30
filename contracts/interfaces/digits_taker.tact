


trait DigitsTakerOut with Registrable {
    // 60 seconds - interval between taking out digits
    virtual const digitTakeInterval: Int = 60;
    registerUntil: Int;
    lastDigitTakenOutDate: Int;
    digitsTakenOut: TookOutDigits;

    inline fun takeRandomDigit(){
        let digitIndex = random(0, 99 - self.digitsTakenOut.count);
        let digit = self.digitsTakenOut.digitAtIndex(digitIndex);

        require(!self.digitsTakenOut.isDigitTookOut(digit), "Digit already taken out");

        self.digitsTakenOut = TookOutDigits{
            data: self.digitsTakenOut.data | (1 << digit),
            count: self.digitsTakenOut.count + 1
        };
    }
    abstract inline fun requireNotEnoughWinners(type: Int);
    abstract inline fun initializeDigits();
    external("take"){
        self.requireRegisterClosed();
        self.initializeDigits();
        require(now() - self.lastDigitTakenOutDate >= self.digitTakeInterval, "Too early to take out digit");
        self.requireNotEnoughWinners(WINNER_TYPE_FULL);
        acceptMessage();
        self.takeRandomDigit();
    }

}