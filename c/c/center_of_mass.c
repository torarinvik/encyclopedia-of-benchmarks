#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_PARTICLES 64
#define MAX_COORDINATE_UNITS 1000000
#define MAX_MASS_UNITS 1000000

/* Round the exact binary64 input to cents, matching Python round(value, 2). */
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
    if (shift < 0) {
        cents = numerator << (unsigned)(-shift);
    } else if (shift == 0) {
        cents = numerator;
    } else if (shift < 64) {
        const uint64_t denominator = UINT64_C(1) << (unsigned)shift;
        cents = numerator >> (unsigned)shift;
        const uint64_t remainder = numerator & (denominator - 1);
        const uint64_t half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) ++cents;
    }
    const double rounded = (double)cents / 100.0;
    return negative ? -rounded : rounded;
}

double center_of_mass(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 4 * MAX_PARTICLES) return INVALID_RESULT;
    const int64_t selector = values[0];
    const int64_t count_value = values[1];
    if (selector < 0 || selector > 2 || count_value < 1 || count_value > MAX_PARTICLES ||
        length != 2 + 4 * (size_t)count_value) return INVALID_RESULT;

    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index) {
        const size_t offset = 2 + 4 * index;
        for (size_t coordinate = 0; coordinate < 3; ++coordinate)
            if (values[offset + coordinate] < -MAX_COORDINATE_UNITS ||
                values[offset + coordinate] > MAX_COORDINATE_UNITS) return INVALID_RESULT;
        if (values[offset + 3] < 1 || values[offset + 3] > MAX_MASS_UNITS) return INVALID_RESULT;
    }

    double total_mass = 0.0;
    for (size_t index = 0; index < count; ++index)
        total_mass += (double)values[2 + 4 * index + 3] / 1000.0;
    double weighted_coordinate = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const size_t offset = 2 + 4 * index;
        const double coordinate = (double)values[offset + (size_t)selector] / 1000.0;
        const double mass = (double)values[offset + 3] / 1000.0;
        weighted_coordinate += coordinate * mass;
    }
    return round_two_python(weighted_coordinate / total_mass);
}
