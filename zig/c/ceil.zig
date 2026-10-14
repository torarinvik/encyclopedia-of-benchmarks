const MAX_VALUES: usize = 256;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_VALUES;
const NUMERATOR_LIMIT: i64 = 1_000_000_000_000;
const DENOMINATOR_LIMIT: i64 = 1_000_000;
const RESULT_OFFSET: i64 = 1_000_000_000_001;

fn ceilDivision(numerator: i64, denominator: i64) i64 {
    if (numerator >= 0) {
        var quotient = @divTrunc(numerator, denominator);
        if (@rem(numerator, denominator) != 0) quotient += 1;
        return quotient;
    }
    return -@divTrunc(-numerator, denominator);
}

export fn ceil_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_VALUES) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_VALUES) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;
    for (0..count) |i| {
        const numerator = values[1 + 2 * i];
        const denominator = values[2 + 2 * i];
        if (numerator < -NUMERATOR_LIMIT or numerator > NUMERATOR_LIMIT or
            denominator < 1 or denominator > DENOMINATOR_LIMIT) return -1;
    }
    var checksum: i64 = 0;
    for (0..count) |i| {
        const result = ceilDivision(values[1 + 2 * i], values[2 + 2 * i]);
        checksum += @as(i64, @intCast(i + 1)) * (result + RESULT_OFFSET);
    }
    return checksum;
}
