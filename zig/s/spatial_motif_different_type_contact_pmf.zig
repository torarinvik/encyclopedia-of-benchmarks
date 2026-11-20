const MAX_LENGTH: i64 = 10;
const MAX_SUPPORT: usize = 11;

fn chooseValue(total: i64, selected0: i64) i64 {
    if (total < 0 or selected0 < 0 or selected0 > total) return 0;
    const selected = @min(selected0, total - selected0);
    var value: i64 = 1;
    var factor: i64 = 1;
    while (factor <= selected) : (factor += 1)
        value = value * (total - selected + factor) / factor;
    return value;
}

fn multinomial3(total: i64, first: i64, second: i64) i64 {
    if (total < 0 or first < 0 or second < 0 or first > total or second > total or
        first + second > total) return 0;
    return chooseValue(total, first) * chooseValue(total - first, second);
}

fn gcdValue(left0: i64, right0: i64) i64 {
    var left = left0;
    var right = right0;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn writeWord(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn spatial_motif_different_type_contact_pmf(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 5) return -1;
    const n0 = input[0];
    const x10 = input[1];
    const y10 = input[2];
    const x20 = input[3];
    const y20 = input[4];
    if (n0 < 1 or n0 > MAX_LENGTH or x10 < 0 or y10 < 0 or x20 < 0 or y20 < 0 or
        x10 > n0 or y10 > n0 or x20 > n0 or y20 > n0) return -1;
    if (x10 + y10 > n0 or x20 + y20 > n0) return -1;

    const n = @as(usize, @intCast(n0));
    const x1 = x10;
    const y1 = y10;
    const x2 = x20;
    const y2 = y20;
    const neither1 = n0 - x10 - y10;
    const denominator = multinomial3(n0, x20, y20);
    var numerators = [_]i64{0} ** MAX_SUPPORT;

    var m: i64 = 0;
    while (m <= n0) : (m += 1) {
        var h: i64 = 0;
        while (h <= x1) : (h += 1) {
            var i: i64 = 0;
            while (i <= x1 - h) : (i += 1) {
                const j = m - i;
                if (j < 0 or j > y1) continue;
                var k: i64 = 0;
                while (k <= y1 - j) : (k += 1) {
                    numerators[@intCast(m)] += multinomial3(x1, h, i)
                        * multinomial3(y1, j, k)
                        * multinomial3(neither1, x2 - h - j, y2 - i - k);
                }
            }
        }
    }

    var expected_numerator: i64 = 0;
    for (0..(n + 1)) |index|
        expected_numerator += @as(i64, @intCast(index)) * numerators[index];
    var expected_denominator = denominator;
    const divisor = gcdValue(expected_numerator, expected_denominator);
    expected_numerator = @divTrunc(expected_numerator, divisor);
    expected_denominator = @divTrunc(expected_denominator, divisor);
    const bytes = (n + 5) * 8;
    if (output == null or capacity < bytes) return -2;
    writeWord(output, 0, n0);
    writeWord(output, 1, denominator);
    for (0..(n + 1)) |index| writeWord(output, index + 2, numerators[index]);
    writeWord(output, n + 3, expected_numerator);
    writeWord(output, n + 4, expected_denominator);
    return @intCast(bytes);
}
