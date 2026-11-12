const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 12;
const MAX_INPUT: usize = 25;
const Coefficients = [MAX_N]i64;
const Basis = [MAX_N + 1]i64;

fn normalize(value: i64) i64 {
    const reduced = @rem(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn powerMod(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn polynomial_interpolation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (0..n) |i| {
        const xi = input[1 + i];
        const yi = input[1 + n + i];
        if (xi < 0 or xi >= MODULUS or yi < 0 or yi >= MODULUS) return -1;
        for (0..i) |j| if (xi == input[1 + j]) return -1;
    }

    const bytes = 8 * n;
    if (output_opt == null or output_capacity < bytes) return -2;
    var coefficients: Coefficients = @splat(0);
    for (0..n) |i| {
        var basis: Basis = @splat(0);
        basis[0] = 1;
        var degree: usize = 0;
        var denominator: i64 = 1;
        for (0..n) |j| {
            if (j == i) continue;
            const xj = input[1 + j];
            denominator = @rem(denominator * (input[1 + i] - xj), MODULUS);
            var expanded: Basis = @splat(0);
            for (0..degree + 1) |k| {
                expanded[k] = normalize(expanded[k] - basis[k] * xj);
                expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
            }
            for (0..degree + 2) |k| basis[k] = expanded[k];
            degree += 1;
        }
        const scale = @rem(input[1 + n + i] * powerMod(normalize(denominator), MODULUS - 2), MODULUS);
        for (0..n) |k| coefficients[k] = @rem(coefficients[k] + scale * basis[k], MODULUS);
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, coefficients[i]);
    return @intCast(bytes);
}
