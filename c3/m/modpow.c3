module modpow;
const long INVALID_RESULT = -9223372036854775807L - 1;
const usz MAX_PARSEABLE_INPUT_LENGTH = 4;
const long MAX_COMPONENT = 89000000;
const long MAX_EXPONENT = 64;
fn long modpow(long* input, usz length) @export("modpow") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length != 3) return INVALID_RESULT;
    long base = input[0], exponent = input[1], modulus = input[2];
    if (base < 0 || base > MAX_COMPONENT || exponent < 0 || exponent > MAX_EXPONENT
        || modulus < 1 || modulus > MAX_COMPONENT) return INVALID_RESULT;
    if (exponent == 0) {
        if (base == 0) return INVALID_RESULT;
        return 1 % modulus;
    }
    if (base == 0) return 0;
    long result = 1 % modulus;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            result = (result * base) % modulus;
            exponent--;
        } else {
            base = (base * base) % modulus;
            exponent /= 2;
        }
    }
    return result;
}
