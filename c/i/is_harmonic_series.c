/* Exact-equality reciprocal progression predicate for IEEE-754 inputs. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_VALUES 32
#define INVALID_RESULT (-1.0e300)

static double decode_binary64(int64_t signed_bits)
{
    const uint64_t bits = (uint64_t)signed_bits;
    double value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

double is_harmonic_series(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_VALUES + 1) return INVALID_RESULT;
    const int64_t count = values[0];
    if (count < 1 || count > MAX_VALUES || length != (size_t)count + 1) return INVALID_RESULT;

    double reciprocals[MAX_VALUES];
    for (size_t i = 0; i < (size_t)count; ++i) {
        const double value = decode_binary64(values[i + 1]);
        if (value == 0.0) return INVALID_RESULT;
        reciprocals[i] = 1.0 / value;
    }
    if (count == 1) return 1.0;
    const double common_difference = reciprocals[1] - reciprocals[0];
    for (size_t i = 2; i < (size_t)count; ++i)
        if (reciprocals[i] - reciprocals[i - 1] != common_difference) return 0.0;
    return 1.0;
}
