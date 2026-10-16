export fn problem24(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var rank: i64 = 999_999;
    var factorial: i64 = 362_880;
    var used: i64 = 0;
    var result: i64 = 0;
    var slots: i64 = 10;
    while (slots > 0) : (slots -= 1) {
        var choice = @divTrunc(rank, factorial);
        rank = @rem(rank, factorial);
        var selected: i64 = -1;
        var digit: i64 = 0;
        while (digit < 10) : (digit += 1) {
            const bit = @as(i64, 1) << @intCast(digit);
            if ((used & bit) == 0) {
                if (choice == 0) {
                    selected = digit;
                    used |= bit;
                    break;
                }
                choice -= 1;
            }
        }
        result = result * 10 + selected;
        if (slots > 1) factorial = @divTrunc(factorial, slots - 1);
    }
    return result;
}
