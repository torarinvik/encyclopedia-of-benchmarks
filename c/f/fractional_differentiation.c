#include <stddef.h>
#include <stdint.h>
#define MAX_WINDOW 8
#define MAX_SERIES 16
#define INVALID_RESULT (-1.0e300)
double fractional_differentiation(const int64_t *values, size_t length) {
    if (values == NULL || length < 4 || length > 18) return INVALID_RESULT;
    int64_t degree_units = values[0], window_value = values[1];
    size_t count = length - 2;
    if (degree_units < 0 || degree_units > 1000000 || window_value < 1 || window_value > MAX_WINDOW ||
        count <= (size_t)window_value || count > MAX_SERIES) return INVALID_RESULT;
    for (size_t i = 0; i < count; ++i) if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return INVALID_RESULT;
    double d = (double)degree_units / 1000000.0;
    double weights[MAX_WINDOW]; weights[0] = 1.0;
    for (size_t k = 1; k < (size_t)window_value; ++k) weights[k] = -weights[k - 1] * (d - (double)k + 1.0) / (double)k;
    double result = 0.0;
    for (size_t j = 0; j < (size_t)window_value; ++j)
        result += weights[j] * ((double)values[2 + count - 1 - j] / 1000.0);
    return result;
}
