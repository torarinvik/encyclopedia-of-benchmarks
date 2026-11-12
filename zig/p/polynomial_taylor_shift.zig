const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;
const Shifted = [MAX_N]i64;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn polynomial_taylor_shift(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    const shift = input[1];
    if (length != n + 2 or shift < 0 or shift >= MODULUS) return -1;
    for (0..n) |i| if (input[i + 2] < 0 or input[i + 2] >= MODULUS) return -1;

    const bytes = 8 * n;
    if (output_opt == null or output_capacity < bytes) return -2;
    var shifted: Shifted = @splat(0);
    var processed: usize = 0;
    var source = n;
    while (source > 0) {
        source -= 1;
        var degree = processed;
        while (degree > 0) {
            degree -= 1;
            shifted[degree + 1] = @rem(shifted[degree + 1] * shift + shifted[degree], MODULUS);
        }
        shifted[0] = @rem(shifted[0] * shift + input[source + 2], MODULUS);
        processed += 1;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, shifted[i]);
    return @intCast(bytes);
}
