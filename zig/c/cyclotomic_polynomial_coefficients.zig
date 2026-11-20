const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 2;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cyclotomic_polynomial_coefficients(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or length != 1) return -1;
    const n: usize = @intCast(n_value);

    var polynomials: [MAX_N + 1][MAX_N + 1]i64 = @splat(@splat(0));
    var degrees: [MAX_N + 1]usize = @splat(0);
    polynomials[1][0] = -1;
    polynomials[1][1] = 1;
    degrees[1] = 1;
    for (2..n + 1) |k| {
        var divisor: [MAX_N + 1]i64 = @splat(0);
        divisor[0] = 1;
        var divisor_degree: usize = 0;
        for (1..k) |d| {
            if (k % d != 0) continue;
            var product: [MAX_N + 1]i64 = @splat(0);
            for (0..divisor_degree + 1) |i| {
                for (0..degrees[d] + 1) |j| {
                    product[i + j] += divisor[i] * polynomials[d][j];
                }
            }
            divisor_degree += degrees[d];
            for (0..divisor_degree + 1) |i| divisor[i] = product[i];
        }

        var remainder: [MAX_N + 1]i64 = @splat(0);
        remainder[0] = -1;
        remainder[k] = 1;
        const quotient_degree = k - divisor_degree;
        degrees[k] = quotient_degree;
        var q: isize = @intCast(quotient_degree);
        while (q >= 0) : (q -= 1) {
            const qi: usize = @intCast(q);
            const leading = remainder[divisor_degree + qi];
            polynomials[k][qi] = leading;
            for (0..divisor_degree + 1) |j|
                remainder[qi + j] -= leading * divisor[j];
        }
    }

    const coefficient_count = degrees[n] + 1;
    const required = coefficient_count * 8;
    if (output == null or capacity < required) return -2;
    const bytes = output.?;
    for (0..coefficient_count) |index|
        storeI64Le(bytes, 8 * index, polynomials[n][index]);
    return @intCast(required);
}
