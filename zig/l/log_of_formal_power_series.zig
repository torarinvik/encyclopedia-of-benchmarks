const modulus: i64 = 998244353;
const max_n: usize = 64;
const max_input: usize = 66;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn log_of_formal_power_series(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    }
    if (input[1] != 1) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var integer_inverse: [max_n]i64 = @splat(0);
    var logarithm: [max_n]i64 = @splat(0);
    if (n > 1) integer_inverse[1] = 1;
    for (2..n) |k| {
        const remainder: usize = @intCast(modulus % @as(i64, @intCast(k)));
        integer_inverse[k] = modulus - (modulus / @as(i64, @intCast(k))) * integer_inverse[remainder] % modulus;
    }
    for (1..n) |degree| {
        var numerator = (@as(i64, @intCast(degree)) * input[degree + 1]) % modulus;
        for (1..degree) |i| {
            var term = (@as(i64, @intCast(i)) * logarithm[i]) % modulus;
            term = term * input[degree - i + 1] % modulus;
            numerator = (numerator - term) % modulus;
            if (numerator < 0) numerator += modulus;
        }
        logarithm[degree] = numerator * integer_inverse[degree] % modulus;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, logarithm[i]);
    return @intCast(bytes);
}
