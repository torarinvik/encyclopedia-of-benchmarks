module powx_n;

fn double pow_positive(double base, long exponent) {
    if (exponent == 0) { return 1.0; }
    long mask = 1;
    while (mask <= exponent / 2) { mask <<= 1; }
    double result = base;
    mask >>= 1;
    while (mask != 0) {
        result *= result;
        if ((exponent & mask) != 0) { result *= base; }
        mask >>= 1;
    }
    return result;
}

fn double powx_n(double base, CInt exponent) @export("powx_n") {
    if (exponent == 0) { return 1.0; }
    if (exponent == -2147483648) {
        return 1.0 / (pow_positive(base, 2147483647) * base);
    }
    if (exponent < 0) { return 1.0 / pow_positive(base, -(long)exponent); }
    return pow_positive(base, exponent);
}
