module modular_exponentiation;

// Binary exponentiation with a normalized base and bounded products.
fn long modular_exponentiation(long* values, usz length) @export("modular_exponentiation") {
    if (values == null || length != 3) return -1;
    long base_input = values[0];
    long exponent_input = values[1];
    long modulus = values[2];
    if (base_input < -2147483648 || base_input > 2147483647 || exponent_input < 0 ||
        exponent_input > 2147483647 || modulus < 1 || modulus > 2147483647) return -1;
    long base = base_input % modulus;
    if (base < 0) base += modulus;
    ulong exponent = (ulong)exponent_input;
    long result = 1 % modulus;
    while (exponent != 0) {
        if ((exponent & 1ul) != 0ul) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}
