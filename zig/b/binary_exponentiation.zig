/// Exponentiation by squaring with exact signed i64 overflow detection.
export fn binary_exponentiation(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const base_input = values[0];
    const exponent_input = values[1];
    if (base_input < 0 or base_input > 2147483647 or exponent_input < 0 or exponent_input > 2147483647) return -1;
    var base: u64 = @intCast(base_input);
    var exponent: u64 = @intCast(exponent_input);
    var result: u64 = 1;
    const maximum: u64 = 9223372036854775807;
    while (exponent != 0) {
        if ((exponent & 1) != 0) {
            if (base != 0 and result > maximum / base) return -1;
            result *= base;
        }
        exponent >>= 1;
        if (exponent != 0) {
            if (base != 0 and base > maximum / base) return -1;
            base *= base;
        }
    }
    return @intCast(result);
}
