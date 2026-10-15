module decimal_to_fraction;

const long INVALID_RESULT = -1;
const long INSUFFICIENT_CAPACITY = -2;

fn void store_i64_le(char* output, usz offset, long value) {
    for (usz i = 0; i < 8; i++) output[offset + i] = (char)((value >> (8 * i)) & 255);
}

fn long gcd_positive(long a, long b) {
    while (b != 0) {
        long remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn long decimal_to_fraction(long* values, usz length, char* output, usz capacity) @export("decimal_to_fraction") {
    long powers10[5] = {1, 10, 100, 1000, 10000};
    long powers5[5] = {1, 5, 25, 125, 625};
    if (values == null || length != 2) return INVALID_RESULT;
    long mantissa = values[0];
    long places = values[1];
    if (places < 0 || places > 4) return INVALID_RESULT;
    long scale = powers10[places];
    long maximum_mantissa = 1000000 * scale;
    if (mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % powers5[places] != 0) return INVALID_RESULT;
    if (output == null || capacity < 16) return INSUFFICIENT_CAPACITY;

    double decimal = (double)mantissa / (double)scale;
    long numerator;
    long denominator;
    if (decimal - (double)(long)decimal == 0.0) {
        numerator = (long)decimal;
        denominator = 1;
    } else {
        long digits = places;
        long magnitude = mantissa < 0 ? -mantissa : mantissa;
        while (digits > 0 && magnitude % 10 == 0) { magnitude /= 10; digits--; }
        numerator = (long)(decimal * (double)powers10[digits]);
        denominator = powers10[digits];
        long abs_numerator = numerator < 0 ? -numerator : numerator;
        long gcd = gcd_positive(abs_numerator, denominator);
        numerator /= gcd;
        denominator /= gcd;
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
