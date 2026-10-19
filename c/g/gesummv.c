#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define INVALID_RESULT (-1e300)

double gesummv(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t n = (size_t)values[0];
    double x[MAX_DIMENSION];
    for (size_t i = 0; i < n; ++i) x[i] = (double)(i % n) / (double)n;
    double result = 0.0;
    for (size_t i = 0; i < n; ++i) {
        double temporary = 0.0;
        double y = 0.0;
        for (size_t j = 0; j < n; ++j) {
            const double a = (double)((i * j + 1) % n) / (double)n;
            const double b = (double)((i * j + 2) % n) / (double)n;
            temporary = a * x[j] + temporary;
            y = b * x[j] + y;
        }
        y = 1.5 * temporary + 1.2 * y;
        result += y;
    }
    return result;
}
