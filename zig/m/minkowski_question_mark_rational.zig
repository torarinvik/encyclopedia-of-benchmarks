const MAX_DENOMINATOR: i64 = 1_000_000;
const MAX_CF_SUM: i64 = 60;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn cfSum(numerator: i64, denominator: i64) i64 {
    var n = numerator;
    var d = denominator;
    var total: i64 = 0;
    while (n != 0) {
        const quotient = @divTrunc(d, n);
        if (quotient > MAX_CF_SUM - total) return -1;
        total += quotient;
        const remainder = @rem(d, n);
        d = n;
        n = remainder;
    }
    return total;
}

fn alternatingNumerator(numerator: i64, denominator: i64, total: i64) i64 {
    var n = numerator;
    var d = denominator;
    var prefix: i64 = 0;
    var index: i64 = 1;
    var value: i64 = 0;
    while (n != 0) {
        const quotient = @divTrunc(d, n);
        prefix += quotient;
        const shift: u6 = @intCast(total - prefix);
        const term: i64 = @as(i64, 1) << shift;
        if (@rem(index, 2) == 1) value += term else value -= term;
        const remainder = @rem(d, n);
        d = n;
        n = remainder;
        index += 1;
    }
    return value;
}

export fn minkowski_question_mark_rational(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 3) return -1;
    if (length != 2) return -1;
    const values = input.?[0..length];
    const p = values[0];
    const q = values[1];
    if (p < 0 or q < 1 or q > MAX_DENOMINATOR or p > q) return -1;
    const total = cfSum(p, q);
    if (total < 0) return -1;
    if (output == null or capacity < 16) return -2;
    const bytes = output.?;
    const value = alternatingNumerator(p, q, total);
    const exponent: i64 = if (total == 0) 0 else total - 1;
    storeI64Le(bytes, 0, value);
    storeI64Le(bytes, 8, exponent);
    return 16;
}
