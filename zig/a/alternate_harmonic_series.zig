const MAX_COUNT: i64 = 1000;

/// Check alternating signs and constant differences between reciprocal magnitudes.
export fn alternate_harmonic_series(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -1;
    const count = input[0];
    if (count < 1 or count > MAX_COUNT or length != @as(usize, @intCast(1 + 2 * count))) return -1;

    var previous_sign: i64 = 0;
    var previous_reciprocal_numerator: i64 = 0;
    var previous_reciprocal_denominator: i64 = 1;
    var step_numerator: i64 = 0;
    var step_denominator: i64 = 1;
    for (0..@as(usize, @intCast(count))) |index| {
        const numerator = input[1 + 2 * index];
        const denominator = input[2 + 2 * index];
        if (numerator < -1000 or numerator > 1000 or numerator == 0 or denominator < 1 or denominator > 1000) return -1;
        const sign: i64 = if (numerator < 0) -1 else 1;
        const magnitude = if (numerator < 0) -numerator else numerator;
        const reciprocal_numerator = denominator;
        const reciprocal_denominator = magnitude;
        if (index > 0) {
            if (index > 1 and sign == previous_sign) return 0;
            const current_delta_numerator = reciprocal_numerator * previous_reciprocal_denominator - previous_reciprocal_numerator * reciprocal_denominator;
            const current_delta_denominator = reciprocal_denominator * previous_reciprocal_denominator;
            if (index == 1) {
                step_numerator = current_delta_numerator;
                step_denominator = current_delta_denominator;
            } else if (current_delta_numerator * step_denominator != step_numerator * current_delta_denominator) {
                return 0;
            }
        }
        previous_sign = sign;
        previous_reciprocal_numerator = reciprocal_numerator;
        previous_reciprocal_denominator = reciprocal_denominator;
    }
    return 1;
}
