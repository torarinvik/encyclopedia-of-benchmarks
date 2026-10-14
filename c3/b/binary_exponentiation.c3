module binary_exponentiation;

// Exact exponentiation by squaring with signed i64 overflow detection.
fn long binary_exponentiation(long* values, usz length) @export("binary_exponentiation") {
    if (values == null || length != 2) return -1;
    long base_input = values[0];
    long exponent_input = values[1];
    if (base_input < 0 || base_input > 2147483647 || exponent_input < 0 || exponent_input > 2147483647) return -1;
    ulong base = (ulong)base_input;
    ulong exponent = (ulong)exponent_input;
    ulong result = 1ul;
    ulong maximum = 9223372036854775807ul;
    while (exponent != 0) {
        if ((exponent & 1ul) != 0ul) {
            if (base != 0ul && result > maximum / base) return -1;
            result *= base;
        }
        exponent >>= 1;
        if (exponent != 0) {
            if (base != 0ul && base > maximum / base) return -1;
            base *= base;
        }
    }
    return (long)result;
}
