/// Clenshaw's backward recurrence for Chebyshev coefficients over a prime field.
const MODULUS: i64 = 998_244_353;
const MAX_DEGREE: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 21;

fn reduceField(value: i64) i64 {
    return @mod(value, MODULUS);
}

export fn chebyshev_clenshaw_evaluation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_LENGTH) return -1;
    const values = input.?;
    const degree_value = values[0];
    const max_degree_i64: i64 = @intCast(MAX_DEGREE);
    if (degree_value < 0 or degree_value > max_degree_i64) return -1;
    const degree: usize = @intCast(degree_value);
    if (length != degree + 3) return -1;
    const x = values[1];
    if (x < 0 or x >= MODULUS) return -1;
    for (0..degree + 1) |i| {
        const coefficient = values[2 + i];
        if (coefficient < 0 or coefficient >= MODULUS) return -1;
    }

    const twice_x = @mod(2 * x, MODULUS);
    var next_one: i64 = 0;
    var next_two: i64 = 0;
    var k = degree;
    while (k > 0) {
        const current = reduceField(values[2 + k] + twice_x * next_one - next_two);
        next_two = next_one;
        next_one = current;
        k -= 1;
    }
    return reduceField(values[2] + x * next_one - next_two);
}
