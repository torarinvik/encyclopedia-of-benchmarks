const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 12;
const MAX_INPUT: usize = 25;
const Coefficients = [MAX_N]i64;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn conversion_from_monomial_basis_to_newton_basis(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, output_capacity: usize,
) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (0..2 * n) |i| if (input[i + 1] < 0 or input[i + 1] >= MODULUS) return -1;

    const bytes = 8 * n;
    if (output_opt == null or output_capacity < bytes) return -2;
    var residual: Coefficients = @splat(0);
    var answer: Coefficients = @splat(0);
    for (0..n) |i| residual[i] = input[i + 1];
    var active = n;
    for (0..n) |i| {
        const node = input[n + 1 + i];
        var value: i64 = 0;
        var degree = active;
        while (degree > 0) {
            degree -= 1;
            value = @rem(value * node + residual[degree], MODULUS);
        }
        answer[i] = value;
        if (active == 1) continue;
        var quotient: Coefficients = @splat(0);
        quotient[active - 2] = residual[active - 1];
        degree = active - 2;
        while (degree > 0) {
            quotient[degree - 1] = @rem(residual[degree] + node * quotient[degree], MODULUS);
            degree -= 1;
        }
        for (0..active - 1) |j| residual[j] = quotient[j];
        active -= 1;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, answer[i]);
    return @intCast(bytes);
}
