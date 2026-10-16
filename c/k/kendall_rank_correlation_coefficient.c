#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 128
#define INVALID_RESULT (-1.0e300)

double kendall_rank_correlation_coefficient(const int64_t *values, size_t length) {
    if (values == NULL || length < 5 || length > 257) return INVALID_RESULT;
    int64_t count = values[0];
    if (count < 2 || count > MAX_OBSERVATIONS || length != 1 + 2 * (size_t)count) return INVALID_RESULT;
    for (size_t i = 0; i < 2 * (size_t)count; ++i)
        if (values[1 + i] < -1000000 || values[1 + i] > 1000000) return INVALID_RESULT;

    int64_t concordant = 0, discordant = 0, ties_x = 0, ties_y = 0;
    size_t n = (size_t)count;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            int64_t x1 = values[1 + i], x2 = values[1 + j];
            int64_t y1 = values[1 + n + i], y2 = values[1 + n + j];
            if (x1 == x2) ++ties_x;
            if (y1 == y2) ++ties_y;
            if ((x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2)) ++concordant;
            else if ((x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2)) ++discordant;
        }
    }
    double pairs = (double)(n * (n - 1) / 2);
    double denominator = sqrt((pairs - (double)ties_x) * (pairs - (double)ties_y));
    if (denominator == 0.0) return INVALID_RESULT;
    return (double)(concordant - discordant) / denominator;
}
