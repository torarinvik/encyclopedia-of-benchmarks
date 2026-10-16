#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_FLOW_COUNT 8

static double round_two_python(double value)
{
    if (value == 0.0) return value;
    const int negative = value < 0.0;
    double normalized = negative ? -value : value;
    int exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; ++exponent; }
    while (normalized < 0.5) { normalized *= 2.0; --exponent; }
    const uint64_t significand = (uint64_t)(normalized * 9007199254740992.0);
    const uint64_t numerator = significand * 100;
    const int shift = 53 - exponent;
    uint64_t cents = 0;
    if (shift < 0) cents = numerator << (unsigned)(-shift);
    else if (shift == 0) cents = numerator;
    else if (shift < 64) {
        const uint64_t denominator = UINT64_C(1) << (unsigned)shift;
        cents = numerator >> (unsigned)shift;
        const uint64_t remainder = numerator & (denominator - 1);
        const uint64_t half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) ++cents;
    }
    const double rounded = (double)cents / 100.0;
    return negative ? -rounded : rounded;
}

double present_value(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 10) return INVALID_RESULT;
    const int64_t count_value = values[0];
    const int64_t rate_ppm = values[1];
    if (count_value < 1 || count_value > MAX_FLOW_COUNT ||
        length != 2 + (size_t)count_value || (rate_ppm != 0 && rate_ppm != 1000000)) return INVALID_RESULT;
    for (size_t i = 0; i < (size_t)count_value; ++i)
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000 || values[i + 2] % 125 != 0) return INVALID_RESULT;
    const double rate = (double)rate_ppm / 1000000.0;
    double total = 0.0;
    for (size_t i = 0; i < (size_t)count_value; ++i) {
        const double cash_flow = (double)values[i + 2] / 1000.0;
        total += cash_flow / pow(1.0 + rate, (double)i);
    }
    return round_two_python(total);
}
