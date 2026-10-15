/// Truncate signed 32-bit division toward zero using doubled divisor chunks.
const INVALID_RESULT: i64 = -2_147_483_649;

export fn divide_two_integers(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const dividend = values[0];
    const divisor = values[1];
    if (dividend < -2147483648 or dividend > 2147483647 or
        divisor < -2147483648 or divisor > 2147483647 or divisor == 0) return INVALID_RESULT;

    var remaining = if (dividend < 0) -dividend else dividend;
    const divisor_magnitude = if (divisor < 0) -divisor else divisor;
    var quotient: i64 = 0;
    var shift: u6 = 32;
    while (shift > 0) {
        shift -= 1;
        if (divisor_magnitude <= (remaining >> shift)) {
            remaining -= divisor_magnitude << shift;
            quotient += @as(i64, 1) << shift;
        }
    }

    const negative = (dividend < 0) != (divisor < 0);
    if (negative) {
        if (quotient == 2147483648) return -2147483648;
        return -quotient;
    }
    return @min(quotient, 2147483647);
}
