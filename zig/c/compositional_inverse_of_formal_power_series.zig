const modulus: i64 = 998244353;
const min_n: usize = 2;
const max_n: usize = 16;
const max_input: usize = 18;

fn modPower(base_value: i64, exponent_value: i64) i64 {
    var base = base_value % modulus;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn compositional_inverse_of_formal_power_series(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < min_n + 1 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < @as(i64, @intCast(min_n)) or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    if (input[1] != 0 or input[2] == 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var powers: [max_n * max_n]i64 = @splat(0);
    var inverse_series: [max_n]i64 = @splat(0);
    const inverse_linear = modPower(input[2], modulus - 2);
    inverse_series[1] = inverse_linear;
    powers[max_n + 1] = inverse_linear;
    for (2..n) |degree| {
        for (2..(degree + 1)) |power| {
            var coefficient: i64 = 0;
            for (1..degree) |split| {
                coefficient = @mod(coefficient + powers[(power - 1) * max_n + degree - split] *
                    inverse_series[split], modulus);
            }
            powers[power * max_n + degree] = coefficient;
        }
        var composed_coefficient: i64 = 0;
        for (2..(degree + 1)) |power| {
            composed_coefficient = @mod(composed_coefficient + input[power + 1] *
                powers[power * max_n + degree], modulus);
        }
        inverse_series[degree] = @mod((modulus - composed_coefficient) * inverse_linear, modulus);
        powers[max_n + degree] = inverse_series[degree];
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, inverse_series[i]);
    return @intCast(bytes);
}
