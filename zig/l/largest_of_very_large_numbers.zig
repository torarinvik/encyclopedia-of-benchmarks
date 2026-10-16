const MAX_VALUE: i64 = 1_000_000_000_000;

fn decimalExponent(input: i64) i64 {
    if (input < 1) return -1;
    var base = input;
    var exponent: i64 = 0;
    while (base > 1 and @rem(base, 10) == 0) {
        base = @divTrunc(base, 10);
        exponent += 1;
    }
    if (base == 1) return exponent;
    return -1;
}

fn validBase(base: i64) bool {
    return base == 0 or decimalExponent(base) >= 0;
}

fn sourceScore(base: i64, exponent: i64) i64 {
    if (base == 0) return 0;
    if (exponent == 0) return 1;
    return decimalExponent(base) * exponent;
}

export fn largest_of_very_large_numbers(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 4) return -2;
    for (0..4) |i| if (values[i] < 0 or values[i] > MAX_VALUE) return -2;
    if (!validBase(values[0]) or !validBase(values[2])) return -2;
    const a = sourceScore(values[0], values[1]);
    const b = sourceScore(values[2], values[3]);
    if (a > b) return 1;
    if (a < b) return -1;
    return 0;
}
