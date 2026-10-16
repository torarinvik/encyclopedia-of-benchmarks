module exponentiation;

fn long exponentiation(long base, long exponent) @export("exponentiation") {
    if (base < 0 || base > 255 || exponent < 0 || exponent > 7) return -1;
    long result = 1;
    for (long i = 0; i < exponent; i++) result *= base;
    return result;
}
