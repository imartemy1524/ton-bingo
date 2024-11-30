

trait Registrable{
    registerUntil: Int;
    inline fun requireCanRegister(){
        require(now() < self.registerUntil, "Registration is closed");
    }
    inline fun requireRegisterClosed(){
        require(now() >= self.registerUntil, "Registration is open");
    }

}