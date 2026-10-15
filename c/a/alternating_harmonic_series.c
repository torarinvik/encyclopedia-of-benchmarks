/* Check rationals against the canonical finite alternating harmonic terms. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 1000

int64_t alternating_harmonic_series(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_COUNT) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;
    if (count == 0) return 0;

    for (size_t index = 0; index < count; ++index) {
        const int64_t numerator = values[1 + 2 * index];
        const int64_t denominator = values[2 + 2 * index];
        if (numerator < -1000 || numerator > 1000 ||
            denominator < 1 || denominator > 1000) return -1;
    }

    for (size_t index = 0; index < count; ++index) {
        const int64_t numerator = values[1 + 2 * index];
        const int64_t denominator = values[2 + 2 * index];
        const int64_t term_index = (int64_t)index + 1;
        const int64_t sign = index % 2 == 0 ? 1 : -1;
        int64_t error = numerator * term_index - sign * denominator;
        if (error < 0) error = -error;
        if (error * 1000000000LL > denominator * term_index) return 0;
    }
    return 1;
}
