const modulus: i64 = 998244353;

fn power(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn newton_reciprocal_fps(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    if (input[1] == 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;
    var inverse: [64]i64 = @splat(0);
    inverse[0] = power(input[1], modulus - 2);
    var precision: usize = 1;
    while (precision < n) {
        const width = @min(2 * precision, n);
        var correction: [64]i64 = @splat(0);
        for (0..width) |i| {
            for (0..@min(precision, width - i)) |j| {
                correction[i + j] = @mod(correction[i + j] + input[i + 1] * inverse[j], modulus);
            }
        }
        correction[0] = @mod(2 + modulus - correction[0], modulus);
        for (1..width) |i| correction[i] = @mod(modulus - correction[i], modulus);
        var next: [64]i64 = @splat(0);
        for (0..precision) |i| {
            for (0..width - i) |j| {
                next[i + j] = @mod(next[i + j] + inverse[i] * correction[j], modulus);
            }
        }
        inverse = next;
        precision = width;
    }
    const output = output_opt.?;
    for (0..n) |i| {
        const bits: u64 = @intCast(inverse[i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(bytes);
}
