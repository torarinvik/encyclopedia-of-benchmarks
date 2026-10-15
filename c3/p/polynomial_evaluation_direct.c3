module polynomial_evaluation_direct;

const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long integer_power(long base, usz exponent) {
    long result = 1;
    for (usz index = 0; index < exponent; index++) result *= base;
    return result;
}

// Bounded integer port of the pinned direct-power polynomial routine.
fn long polynomial_evaluation_direct(long* values, usz length) @export("polynomial_evaluation_direct") {
    if (values == null || length < 2 || length > 10) return INVALID_RESULT;
    long count = values[0];
    long x = values[1];
    if (count < 0 || count > 8 || length != (usz)(count + 2)) return INVALID_RESULT;
    if (x < -10 || x > 10) return INVALID_RESULT;
    for (usz index = 0; index < (usz)count; index++) {
        if (values[index + 2] < -1000 || values[index + 2] > 1000) return INVALID_RESULT;
    }
    long result = 0;
    for (usz index = 0; index < (usz)count; index++) {
        result += values[index + 2] * integer_power(x, index);
    }
    return result;
}
