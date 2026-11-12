const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 32;
const MAX_INPUT: usize = 34;
const MAX_EXPONENT: i64 = 1_000_000_000_000_000_000;
const Polynomial = [MAX_N]i64;

fn multiplyTruncated(left: *const Polynomial, right: *const Polynomial, n: usize) Polynomial {
    var product: Polynomial = @splat(0);
    for (0..n) |i| {
        for (0..(n - i)) |j| {
            product[i + j] = @rem(product[i + j] + left[i] * right[j], MODULUS);
        }
    }
    return product;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn pow_of_formal_power_series(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))
            or input[1] < 0 or input[1] > MAX_EXPONENT) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 2) return -1;
    for (0..n) |i| if (input[i + 2] < 0 or input[i + 2] >= MODULUS) return -1;

    const bytes = 8 * n;
    if (output_opt == null or output_capacity < bytes) return -2;
    var result: Polynomial = @splat(0);
    var base: Polynomial = @splat(0);
    result[0] = 1;
    for (0..n) |i| base[i] = input[i + 2];
    var exponent = input[1];
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = multiplyTruncated(&result, &base, n);
        exponent = @divTrunc(exponent, 2);
        if (exponent > 0) base = multiplyTruncated(&base, &base, n);
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, result[i]);
    return @intCast(bytes);
}
