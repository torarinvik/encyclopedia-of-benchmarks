const MODULUS: i64 = 998244353;

export fn prefix_sum_of_binomial_coefficient(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 34) return -1;
    const count_value = input[0];
    if (count_value < 1 or count_value > 16) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;
    var ns: [16]i64 = undefined;
    var ks: [16]i64 = undefined;
    for (0..count) |query| {
        ns[query] = input[1 + 2 * query];
        ks[query] = input[2 + 2 * query];
        if (ns[query] < 0 or ns[query] > 128 or ks[query] < 0 or ks[query] > ns[query]) return -1;
    }
    const output_length = 4 * count;
    if (output == null or capacity < output_length) return -2;

    var inverse = [_]i64{0} ** 129;
    inverse[1] = 1;
    for (2..129) |value| {
        const v: i64 = @intCast(value);
        const remainder: usize = @intCast(@mod(MODULUS, v));
        inverse[value] = MODULUS - @mod(@divTrunc(MODULUS, v) * inverse[remainder], MODULUS);
    }
    for (0..count) |query| {
        var coefficient: i64 = 1;
        var prefix: i64 = 1;
        var index: i64 = 0;
        while (index < ks[query]) : (index += 1) {
            coefficient = @mod(coefficient * (ns[query] - index), MODULUS);
            coefficient = @mod(coefficient * inverse[@intCast(index + 1)], MODULUS);
            prefix = @mod(prefix + coefficient, MODULUS);
        }
        const residue: u32 = @intCast(prefix);
        const offset = 4 * query;
        output[offset] = @intCast(residue & 255);
        output[offset + 1] = @intCast((residue >> 8) & 255);
        output[offset + 2] = @intCast((residue >> 16) & 255);
        output[offset + 3] = @intCast((residue >> 24) & 255);
    }
    return @intCast(output_length);
}
