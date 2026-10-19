fn power_using_recursion_value(base: i64, exponent: i64) i64 {
    if (exponent == 0) return 1;
    return base * power_using_recursion_value(base, exponent - 1);
}

export fn power_using_recursion(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..length];
    const base = values[0];
    const exponent = values[1];
    if (base < -10 or base > 10 or exponent < 0 or exponent > 15) return -1;
    return power_using_recursion_value(base, exponent);
}
