inline fun genLinkFor(number: Int): String {
    return beginString().concat("https://raw.githubusercontent.com/imartemy1524/ton-bingo/refs/heads/master/images/").concat(number.toString()).concat(".png").toString()
}

inline fun generateSvg(background: String, ticket: Ticket, images: map<Int, ElString>): String {
    let ans = beginString().concat(
    "<svg width=\"1024\" height=\"1024\" xmlns=\"http://www.w3.org/2000/svg\"><image href=\""
    )
    .concat(background)
    .concat("\" x=\"0\" y=\"0\" width=\"1024\" height=\"1024\"/>");

    let yPos: Int = 0;
    let y: Int = 325;
    repeat(5){
        let x: Int = 350;
        let xPos: Int = 0;
        repeat(5){
            if(xPos != 2 || yPos != 2){
                let value = ticket.numberAt(xPos, yPos);
                ans = ans.concat("<image x=\"").concat(x.toString()).concat("\" y=\"").concat(y.toString()).concat("\" width=\"150\" height=\"150\" href=\"data:image/png;base64,").concat(images.get(value)!!.value).concat("\" />");
            }
            x += 123;
            xPos += 1;
        }
        y += 123;
        yPos += 1;
    }
    return ans.concat("</svg>").toString();
}

