module continued_fraction;

fn long gcd_positive(long left, long right) {
    while (right != 0) { long remainder = left % right; left = right; right = remainder; }
    return left;
}

fn long continued_fraction(long* input, usz length, char* output, usz capacity)
        @export("continued_fraction") {
    if (input == null || length != 2) return -1;
    long numerator = input[0], denominator = input[1];
    if (numerator < -1000000 || numerator > 1000000 || denominator < -1000000 ||
        denominator > 1000000 || denominator == 0) return -1;
    long divisor = gcd_positive(numerator < 0 ? -numerator : numerator,
                                denominator < 0 ? -denominator : denominator);
    numerator /= divisor; denominator /= divisor;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }

    long[32] coefficients = {0};
    usz count = 0;
    while (true) {
        long quotient = numerator / denominator;
        long remainder = numerator % denominator;
        if (remainder < 0) { quotient--; remainder += denominator; }
        if (count == 32) return -1;
        coefficients[count++] = quotient;
        if (remainder == 0) break;
        numerator = denominator; denominator = remainder;
    }
    usz bytes = count * 8;
    if (bytes > capacity || output == null) return -2;
    for (usz i = 0; i < count; i++) {
        ulong bits = @bitcast(ulong, coefficients[i]);
        for (usz byte = 0; byte < 8; byte++) output[i * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return (long)bytes;
}
