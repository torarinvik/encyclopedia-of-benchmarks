/// Infinite geometric-weighted power sum via an Eulerian polynomial row.
const MODULUS: i64 = 998244353;
const MAX_DEGREE: usize = 256;

fn sepplModPow(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn sum_of_exponential_times_polynomial_limit(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const r = input[0];
    const degree_value = input[1];
    if (r < 0 or r >= MODULUS or r == 1 or degree_value < 0 or degree_value > @as(i64, @intCast(MAX_DEGREE))) return -1;
    const degree: usize = @intCast(degree_value);
    const denominator = @mod(1 - r + MODULUS, MODULUS);
    const inverse = sepplModPow(denominator, MODULUS - 2);
    if (degree == 0) return inverse;

    var row: [MAX_DEGREE + 1]i64 = [_]i64{0} ** (MAX_DEGREE + 1);
    var next_row: [MAX_DEGREE + 1]i64 = [_]i64{0} ** (MAX_DEGREE + 1);
    row[0] = 1;
    for (1..degree + 1) |n| {
        for (0..n + 1) |k| {
            var value: i64 = 0;
            if (k > 0) value += @as(i64, @intCast(n - k)) * row[k - 1];
            if (k < n) value += @as(i64, @intCast(k + 1)) * row[k];
            next_row[k] = @mod(value, MODULUS);
        }
        for (0..n + 1) |k| {
            row[k] = next_row[k];
            next_row[k] = 0;
        }
    }

    var eulerian_value: i64 = 0;
    var k = degree;
    while (k > 0) {
        k -= 1;
        eulerian_value = @mod(eulerian_value * r + row[k], MODULUS);
    }
    const denominator_power = sepplModPow(inverse, @as(i64, @intCast(degree)) + 1);
    return @mod(@mod(r * eulerian_value, MODULUS) * denominator_power, MODULUS);
}
