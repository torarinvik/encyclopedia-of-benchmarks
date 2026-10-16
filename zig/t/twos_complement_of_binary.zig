const MAX_BINARY_DIGIT_NUMERAL: i64 = 1111111111111111;

export fn twos_complement_of_binary(value: i64) i64 {
    if (value < 0 or value > MAX_BINARY_DIGIT_NUMERAL) return -1;
    if (value == 0) return 0;

    var remaining = value;
    while (remaining > 0) {
        const digit = @rem(remaining, 10);
        if (digit != 0 and digit != 1) return -1;
        remaining = @divTrunc(remaining, 10);
    }

    remaining = value;
    var reversed: i64 = 0;
    var width: i64 = 0;
    while (remaining > 0 and @rem(remaining, 10) == 0) {
        reversed = reversed * 10 + @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
        width += 1;
    }
    if (remaining > 0) {
        reversed = reversed * 10 + @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
        width += 1;
    }
    while (remaining > 0) {
        const digit = @rem(remaining, 10);
        reversed = reversed * 10 + (if (digit == 1) @as(i64, 0) else @as(i64, 1));
        remaining = @divTrunc(remaining, 10);
        width += 1;
    }

    var result: i64 = 0;
    while (width > 0) {
        result = result * 10 + @rem(reversed, 10);
        reversed = @divTrunc(reversed, 10);
        width -= 1;
    }
    return result;
}
