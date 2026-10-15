#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define INSUFFICIENT_CAPACITY INT64_C(-2)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

static int64_t gcd_positive(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

int64_t decimal_to_fraction(const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    static const int64_t powers10[] = {1, 10, 100, 1000, 10000};
    static const int64_t powers5[] = {1, 5, 25, 125, 625};
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mantissa = values[0];
    const int64_t places = values[1];
    if (places < 0 || places > 4) return INVALID_RESULT;
    const int64_t scale = powers10[places];
    const int64_t maximum_mantissa = INT64_C(1000000) * scale;
    if (mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % powers5[places] != 0)
        return INVALID_RESULT;
    if (output == NULL || capacity < 16) return INSUFFICIENT_CAPACITY;

    const double decimal = (double)mantissa / (double)scale;
    int64_t numerator;
    int64_t denominator;
    if (decimal - (double)(int64_t)decimal == 0.0) {
        numerator = (int64_t)decimal;
        denominator = 1;
    } else {
        int64_t digits = places;
        int64_t magnitude = mantissa < 0 ? -mantissa : mantissa;
        while (digits > 0 && magnitude % 10 == 0) { magnitude /= 10; --digits; }
        double multiplier = (double)powers10[digits];
        numerator = (int64_t)(decimal * multiplier);
        denominator = powers10[digits];
        const int64_t gcd = gcd_positive(numerator < 0 ? -numerator : numerator, denominator);
        numerator /= gcd;
        denominator /= gcd;
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
