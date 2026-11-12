const modulus: i64 = 998244353;
const max_n: usize = 64;
const max_input: usize = 66;

fn powerMod(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (exponent & 1 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn inv_of_formal_power_series(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    }
    if (input[1] == 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var inverse: [max_n]i64 = @splat(0);
    const inverse_constant = powerMod(input[1], modulus - 2);
    inverse[0] = inverse_constant;
    for (1..n) |degree| {
        var sum: i64 = 0;
        for (1..(degree + 1)) |i| {
            sum = (sum + input[i + 1] * inverse[degree - i]) % modulus;
        }
        inverse[degree] = (modulus - inverse_constant * sum % modulus) % modulus;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, inverse[i]);
    return @intCast(bytes);
}
