const MAX_VALUE: i64 = 1_000_000_000_000;

fn sourceScore(base: i64, exponent: i64) f64 {
    if (base == 0) return 0.0;
    if (exponent == 0) return 1.0;
    return @as(f64, @floatFromInt(exponent)) * @log10(@as(f64, @floatFromInt(base)));
}

fn validComparisonDomain(baseA: i64, exponentA: i64, baseB: i64, exponentB: i64) bool {
    return exponentA == exponentB or
        (baseA == baseB and (baseA == 0 or ((exponentA == 0) == (exponentB == 0))));
}

export fn largest_of_very_large_numbers(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 4) return -2;
    for (0..4) |i| if (values[i] < 0 or values[i] > MAX_VALUE) return -2;
    if (!validComparisonDomain(values[0], values[1], values[2], values[3])) return -2;
    const a = sourceScore(values[0], values[1]);
    const b = sourceScore(values[2], values[3]);
    if (a > b) return 1;
    if (a < b) return -1;
    return 0;
}
