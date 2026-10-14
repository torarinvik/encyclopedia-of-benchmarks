/// Binary exponentiation under a positive signed 32-bit modulus.
export fn modular_exponentiation(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    const base_input = values[0];
    const exponent_input = values[1];
    const modulus = values[2];
    if (base_input < -2147483648 or base_input > 2147483647 or exponent_input < 0 or
        exponent_input > 2147483647 or modulus < 1 or modulus > 2147483647) return -1;
    var base = @rem(base_input, modulus);
    if (base < 0) base += modulus;
    var exponent: u64 = @intCast(exponent_input);
    var result: i64 = @rem(1, modulus);
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}
