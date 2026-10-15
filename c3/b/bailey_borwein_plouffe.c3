module bailey_borwein_plouffe;

extern fn double pow(double base, double exponent);
extern fn double floor(double value);

fn long modular_power_16(long exponent, long modulus)
{
    long result = 1 % modulus;
    long base = 16 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent = exponent >> 1;
    }
    return result;
}

fn double bbp_subsum(long position, long addend)
{
    double total = 0.0;
    for (long index = 0; index < position + 1000; index++) {
        long denominator = 8 * index + addend;
        long exponent = position - 1 - index;
        double term = index < position
            ? (double)modular_power_16(exponent, denominator) / (double)denominator
            : pow(16.0, (double)exponent) / (double)denominator;
        total += term;
    }
    return total;
}

fn long bailey_borwein_plouffe(long digit_position) @export("bailey_borwein_plouffe")
{
    if (digit_position < 1 || digit_position > 10) return -1;
    double sum_result = 4.0 * bbp_subsum(digit_position, 1)
        - 2.0 * bbp_subsum(digit_position, 4)
        - bbp_subsum(digit_position, 5)
        - bbp_subsum(digit_position, 6);
    double fractional = sum_result - floor(sum_result);
    return (long)(fractional * 16.0);
}
