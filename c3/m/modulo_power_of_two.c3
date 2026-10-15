module modulo_power_of_two;

// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
fn long modulo_power_of_two(long* values, usz length) @export("modulo_power_of_two") {
    if (values == null || length != 2) return -1;
    long x = values[0];
    long exponent = values[1];
    if (x < -2147483648 || x > 2147483647 || exponent < 1 || exponent > 31) return -1;
    long mask = ((long)1 << (usz)exponent) - 1;
    return x & mask;
}
