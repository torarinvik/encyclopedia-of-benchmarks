module power_using_recursion;

fn long power_recursive(long base, long exponent) {
    if (exponent == 0) return 1;
    return base * power_recursive(base, exponent - 1);
}

fn long power_using_recursion(long* input, usz length) @export("power_using_recursion") {
    if (input == null || length != 2) return -1;
    long base = input[0];
    long exponent = input[1];
    if (base < -10 || base > 10 || exponent < 0 || exponent > 15) return -1;
    return power_recursive(base, exponent);
}
