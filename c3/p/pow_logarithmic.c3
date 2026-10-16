module pow_logarithmic;
const long INVALID_RESULT = -9223372036854775807L - 1;
const usz MAX_PARSEABLE_INPUT_LENGTH = 3;
fn long pow_logarithmic_value(long base, usz exponent) {
    if (exponent == 0) return 1;
    long half = pow_logarithmic_value(base, exponent / 2);
    long square = half * half;
    return exponent % 2 == 0 ? square : square * base;
}
fn long pow_logarithmic(long* input, usz length) @export("pow_logarithmic") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length != 2) return INVALID_RESULT;
    long base = input[0], raw_exponent = input[1];
    if (base < -10 || base > 10 || raw_exponent < 0 || raw_exponent > 15) return INVALID_RESULT;
    return pow_logarithmic_value(base, (usz)raw_exponent);
}
