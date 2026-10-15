/* Truncate signed 32-bit division toward zero using doubled divisor chunks. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(2147483649))

int64_t divide_two_integers(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t dividend = values[0];
    const int64_t divisor = values[1];
    if (dividend < INT32_MIN || dividend > INT32_MAX ||
        divisor < INT32_MIN || divisor > INT32_MAX || divisor == 0) return INVALID_RESULT;

    int64_t remaining = dividend < 0 ? -dividend : dividend;
    const int64_t divisor_magnitude = divisor < 0 ? -divisor : divisor;
    int64_t quotient = 0;
    for (int shift = 31; shift >= 0; --shift) {
        if (divisor_magnitude <= (remaining >> shift)) {
            remaining -= divisor_magnitude << shift;
            quotient += INT64_C(1) << shift;
        }
    }

    const int negative = (dividend < 0) != (divisor < 0);
    if (negative) return quotient == INT64_C(2147483648) ? INT32_MIN : -quotient;
    return quotient > INT32_MAX ? INT32_MAX : quotient;
}
