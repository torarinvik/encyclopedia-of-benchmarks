const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 16;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 20;
const Values = [MAX_N]i64;

fn modPow(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn shift_of_sampling_points_of_polynomial(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    const start = input[2];
    if (length != n + 3 or start < 0 or start >= MODULUS) return -1;
    for (0..n) |i| if (input[i + 3] < 0 or input[i + 3] >= MODULUS) return -1;

    const bytes = 8 * m;
    if (output_opt == null or output_capacity < bytes) return -2;
    var differences: Values = @splat(0);
    var newton: Values = @splat(0);
    var factorial: Values = @splat(0);
    var inverse_factorial: Values = @splat(0);
    for (0..n) |i| differences[i] = input[i + 3];
    factorial[0] = 1;
    for (1..n) |k| factorial[k] = @rem(factorial[k - 1] * @as(i64, @intCast(k)), MODULUS);
    inverse_factorial[n - 1] = modPow(factorial[n - 1], MODULUS - 2);
    var k = n - 1;
    while (k > 0) : (k -= 1)
        inverse_factorial[k - 1] = @rem(inverse_factorial[k] * @as(i64, @intCast(k)), MODULUS);
    for (0..n) |degree| {
        newton[degree] = @rem(differences[0] * inverse_factorial[degree], MODULUS);
        for (0..(n - degree - 1)) |i| {
            differences[i] = differences[i + 1] - differences[i];
            if (differences[i] < 0) differences[i] += MODULUS;
        }
    }

    const output = output_opt.?;
    for (0..m) |offset| {
        var x = start + @as(i64, @intCast(offset));
        if (x >= MODULUS) x -= MODULUS;
        var basis: i64 = 1;
        var value: i64 = 0;
        for (0..n) |degree| {
            value = @rem(value + newton[degree] * basis, MODULUS);
            var factor = x - @as(i64, @intCast(degree));
            if (factor < 0) factor += MODULUS;
            basis = @rem(basis * factor, MODULUS);
        }
        storeLe(output, 8 * offset, value);
    }
    return @intCast(bytes);
}
