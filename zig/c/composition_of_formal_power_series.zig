const modulus: i64 = 998244353;
const max_n: usize = 16;
const max_input: usize = 34;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn composition_of_formal_power_series(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (0..2 * n) |i| {
        if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    }
    if (input[1 + n] != 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var composed: [max_n]i64 = @splat(0);
    var outer = n;
    while (outer > 0) {
        var bound = n;
        while (bound > 1) {
            const degree = bound - 1;
            var sum: i64 = 0;
            for (1..(degree + 1)) |inner_degree| {
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % modulus;
            }
            composed[degree] = sum;
            bound -= 1;
        }
        composed[0] = input[outer];
        outer -= 1;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, composed[i]);
    return @intCast(bytes);
}
