/* Check alternating signs and a constant step in reciprocal magnitudes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 1000

int64_t alternate_harmonic_series(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1) return -1;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;

    for (size_t index = 0; index < count; ++index) {
        const int64_t numerator = values[1 + 2 * index];
        const int64_t denominator = values[2 + 2 * index];
        if (numerator < -1000 || numerator > 1000 || numerator == 0 ||
            denominator < 1 || denominator > 1000) return -1;
    }

    int64_t previous_difference_numerator = 0;
    int64_t previous_difference_denominator = 1;
    int64_t previous_magnitude = 0;
    int64_t previous_denominator = 0;

    for (size_t index = 0; index < count; ++index) {
        const int64_t numerator = values[1 + 2 * index];
        const int64_t denominator = values[2 + 2 * index];
        const int64_t magnitude = numerator < 0 ? -numerator : numerator;

        if (index > 0) {
            if ((numerator < 0) == (values[1 + 2 * (index - 1)] < 0)) return 0;
            const int64_t difference_numerator =
                denominator * previous_magnitude - previous_denominator * magnitude;
            const int64_t difference_denominator = magnitude * previous_magnitude;
            if (index > 1 &&
                difference_numerator * previous_difference_denominator !=
                    previous_difference_numerator * difference_denominator) return 0;
            previous_difference_numerator = difference_numerator;
            previous_difference_denominator = difference_denominator;
        }
        previous_magnitude = magnitude;
        previous_denominator = denominator;
    }
    return 1;
}
