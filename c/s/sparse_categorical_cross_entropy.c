#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
double sparse_categorical_cross_entropy(const int64_t *values, size_t length) {
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t batch = values[0], classes = values[1];
    if (batch < 1 || batch > 32 || classes < 1 || classes > 32 || length != 2 + (size_t)batch + (size_t)batch * (size_t)classes) return INVALID_RESULT;
    for (size_t r = 0; r < (size_t)batch; r++) {
        int64_t label = values[2 + r], row_sum = 0;
        if (label < 0 || label >= classes) return INVALID_RESULT;
        for (size_t c = 0; c < (size_t)classes; c++) { int64_t x = values[2 + (size_t)batch + r * (size_t)classes + c]; if (x < 0 || x > 1000000) return INVALID_RESULT; row_sum += x; }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (size_t r = 0; r < (size_t)batch; r++) { double p = (double)values[2 + (size_t)batch + r * (size_t)classes + (size_t)values[2 + r]] / SCALE; if (p < 1e-15) p = 1e-15; total += -log(p); }
    return total;
}
