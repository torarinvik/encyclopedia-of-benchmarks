const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4;
const MAX_COMPONENT: i64 = 89_000_000;
const MAX_EXPONENT: i64 = 64;
export fn modpow(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    if (length != 3) return INVALID_RESULT;
    var base = values[0];
    var exponent = values[1];
    const modulus = values[2];
    if (base < 0 or base > MAX_COMPONENT or exponent < 0 or exponent > MAX_EXPONENT
        or modulus < 1 or modulus > MAX_COMPONENT) return INVALID_RESULT;
    if (exponent == 0) {
        if (base == 0) return INVALID_RESULT;
        return @mod(1, modulus);
    }
    if (base == 0) return 0;
    var result = @mod(1, modulus);
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) {
            result = @mod(result * base, modulus);
            exponent -= 1;
        } else {
            base = @mod(base * base, modulus);
            exponent = @divTrunc(exponent, 2);
        }
    }
    return result;
}
