const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;
fn pow_logarithmic_value(base: i64, exponent: usize) i64 {
    if (exponent == 0) return 1;
    const half = pow_logarithmic_value(base, exponent / 2);
    const square = half * half;
    return if (exponent % 2 == 0) square else square * base;
}
export fn pow_logarithmic(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    if (length != 2) return INVALID_RESULT;
    const base = values[0];
    const exponent = values[1];
    if (base < -10 or base > 10 or exponent < 0 or exponent > 15) return INVALID_RESULT;
    return pow_logarithmic_value(base, @intCast(exponent));
}
