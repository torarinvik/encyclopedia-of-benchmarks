const MAX_PARSEABLE_INPUT_LENGTH = 2;

fn digitFactor(digit: i64) i64 {
    return switch (digit) {
        0, 1 => 1,
        2 => 2,
        3 => 6,
        else => 4,
    };
}

fn twoPowerMod10(exponent_mod_four: i64) i64 {
    return switch (exponent_mod_four) {
        0 => 1,
        1 => 2,
        2 => 4,
        else => 8,
    };
}

export fn factorial_last_nonzero_digit(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 0) return -1;

    var n = input[0];
    var result: i64 = 1;
    while (n >= 5) {
        const quotient = @divTrunc(n, 5);
        const remainder = @rem(n, 5);
        result = @rem(result * digitFactor(remainder), 10);
        result = @rem(result * twoPowerMod10(@rem(quotient, 4)), 10);
        n = quotient;
    }
    return @rem(result * digitFactor(n), 10);
}
