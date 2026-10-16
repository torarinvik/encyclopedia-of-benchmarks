#include <stddef.h>
#include <stdint.h>

#define MAX_SERIES_LENGTH 16
#define MAX_SAMPLE_VALUE 1000
#define INVALID_RESULT (-1.0e300)
#define UNREACHABLE 1.0e300

double dynamic_time_warping(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 35) return INVALID_RESULT;
    const int64_t first_length_value = values[0];
    const int64_t second_length_value = values[1];
    const int64_t band_value = values[2];
    if (first_length_value < 1 || first_length_value > MAX_SERIES_LENGTH ||
        second_length_value < 1 || second_length_value > MAX_SERIES_LENGTH) return INVALID_RESULT;
    const size_t first_length = (size_t)first_length_value;
    const size_t second_length = (size_t)second_length_value;
    const int64_t difference = first_length_value > second_length_value
        ? first_length_value - second_length_value : second_length_value - first_length_value;
    if (band_value < difference || band_value > MAX_SERIES_LENGTH ||
        length != 3 + first_length + second_length) return INVALID_RESULT;
    const size_t band = (size_t)band_value;
    for (size_t i = 0; i < first_length + second_length; ++i) {
        if (values[3 + i] < -MAX_SAMPLE_VALUE || values[3 + i] > MAX_SAMPLE_VALUE) return INVALID_RESULT;
    }

    double rows[2][MAX_SERIES_LENGTH + 1];
    for (size_t j = 0; j <= second_length; ++j) rows[0][j] = UNREACHABLE;
    rows[0][0] = 0.0;
    for (size_t i = 1; i <= first_length; ++i) {
        const size_t current = i % 2;
        const size_t previous = (i - 1) % 2;
        for (size_t j = 0; j <= second_length; ++j) rows[current][j] = UNREACHABLE;
        const size_t start = i > band ? i - band : 1;
        const size_t end = i + band < second_length ? i + band : second_length;
        for (size_t j = start; j <= end; ++j) {
            int64_t difference_value = values[3 + i - 1] - values[3 + first_length + j - 1];
            if (difference_value < 0) difference_value = -difference_value;
            double best = rows[previous][j];
            if (rows[current][j - 1] < best) best = rows[current][j - 1];
            if (rows[previous][j - 1] < best) best = rows[previous][j - 1];
            rows[current][j] = (double)difference_value + best;
        }
    }
    return rows[first_length % 2][second_length];
}
