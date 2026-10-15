/// Bounded integer port of the pinned direct-power polynomial routine.
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn integer_power(base: i64, exponent: usize) i64 {
    var result: i64 = 1;
    for (0..exponent) |_| result *= base;
    return result;
}

export fn polynomial_evaluation_direct(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 10) return INVALID_RESULT;
    const count = values[0];
    const x = values[1];
    if (count < 0 or count > 8 or length != @as(usize, @intCast(count)) + 2) return INVALID_RESULT;
    if (x < -10 or x > 10) return INVALID_RESULT;
    const coefficient_count: usize = @intCast(count);
    for (0..coefficient_count) |index| {
        const coefficient = values[index + 2];
        if (coefficient < -1000 or coefficient > 1000) return INVALID_RESULT;
    }
    var result: i64 = 0;
    for (0..coefficient_count) |index| {
        result += values[index + 2] * integer_power(x, index);
    }
    return result;
}
