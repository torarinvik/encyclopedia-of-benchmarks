#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 62
#define INVALID_RESULT INT64_C(-1)

static double type7_quantile(const int64_t *sorted, size_t count, double probability) {
    double h = (double)(count - 1) * probability + 1.0;
    size_t order = (size_t)h;
    double fraction = h - (double)order;
    size_t lower = order - 1;
    if (fraction == 0.0 || lower + 1 >= count) return (double)sorted[lower];
    return (1.0 - fraction) * (double)sorted[lower] + fraction * (double)sorted[lower + 1];
}

int64_t iqr_outlier_indices(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    int64_t sorted[MAX_LENGTH];
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
        size_t j = i;
        while (j > 0 && sorted[j - 1] > values[i]) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = values[i];
    }
    double q1 = type7_quantile(sorted, length, 0.25);
    double q3 = type7_quantile(sorted, length, 0.75);
    double iqr = q3 - q1;
    double lower_bound = q1 - 1.5 * iqr;
    double upper_bound = q3 + 1.5 * iqr;
    int64_t mask = 0;
    for (size_t i = 0; i < length; ++i)
        if ((double)values[i] < lower_bound || (double)values[i] > upper_bound) mask |= INT64_C(1) << i;
    return mask;
}
