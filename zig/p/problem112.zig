fn isBouncy(value_in: i64) bool {
    var value = value_in;
    var increasing = false;
    var decreasing = false;
    var previous = @rem(value, 10);
    value = @divTrunc(value, 10);
    while (value > 0) {
        const digit = @rem(value, 10);
        if (digit < previous) increasing = true;
        if (digit > previous) decreasing = true;
        previous = digit;
        value = @divTrunc(value, 10);
    }
    return increasing and decreasing;
}

export fn problem112(percent: i64) i64 {
    if (percent < 1 or percent > 99) return -1;
    var bouncy: i64 = 0;
    var n: i64 = 1;
    while (true) {
        if (isBouncy(n)) bouncy += 1;
        if (bouncy * 100 >= percent * n) return n;
        n += 1;
    }
}
