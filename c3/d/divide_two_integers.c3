module divide_two_integers;

const INVALID_RESULT = -2147483649L;

// Truncate signed 32-bit division toward zero using doubled divisor chunks.
fn long divide_two_integers(long* values, usz length) @export("divide_two_integers") {
    if (values == null || length != 2) { return INVALID_RESULT; }
    long dividend = values[0];
    long divisor = values[1];
    if (dividend < -2147483648L || dividend > 2147483647L ||
        divisor < -2147483648L || divisor > 2147483647L || divisor == 0) { return INVALID_RESULT; }

    long remaining = dividend < 0 ? -dividend : dividend;
    long divisor_magnitude = divisor < 0 ? -divisor : divisor;
    long quotient = 0;
    for (int shift = 31; shift >= 0; shift--) {
        if (divisor_magnitude <= (remaining >> shift)) {
            remaining -= divisor_magnitude << shift;
            quotient += 1L << shift;
        }
    }

    bool negative = (dividend < 0) != (divisor < 0);
    if (negative) {
        if (quotient == 2147483648L) { return -2147483648L; }
        return -quotient;
    }
    return quotient > 2147483647L ? 2147483647L : quotient;
}
