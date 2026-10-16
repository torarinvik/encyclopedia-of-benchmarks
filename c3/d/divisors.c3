module divisors;

// Encode the source divisor list in a lossless positive signed-i64 bit mask.
fn long divisors(long* values, usz length) @export("divisors")
{
    if (values == null || length != 1) return -1;
    long n = values[0];
    if (n < 1 || n > 62) return -1;
    long mask = 0;
    for (long divisor = 1; divisor <= n; divisor++) {
        if (n % divisor == 0) mask |= 1L << divisor;
    }
    return mask;
}
