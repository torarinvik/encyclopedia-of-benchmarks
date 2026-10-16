#include <cmath>
#include <cstddef>
#include <cstdint>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
extern "C" double sparse_categorical_cross_entropy(const std::int64_t *values, std::size_t length) {
    if (values == NULL || length < 2) return INVALID_RESULT;
    const std::int64_t batch = values[0], classes = values[1];
    if (batch < 1 || batch > 32 || classes < 1 || classes > 32 || length != 2 + (std::size_t)batch + (std::size_t)batch * (std::size_t)classes) return INVALID_RESULT;
    for (std::size_t r = 0; r < (std::size_t)batch; r++) {
        std::int64_t label = values[2 + r], row_sum = 0;
        if (label < 0 || label >= classes) return INVALID_RESULT;
        for (std::size_t c = 0; c < (std::size_t)classes; c++) { std::int64_t x = values[2 + (std::size_t)batch + r * (std::size_t)classes + c]; if (x < 0 || x > 1000000) return INVALID_RESULT; row_sum += x; }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (std::size_t r = 0; r < (std::size_t)batch; r++) { double p = (double)values[2 + (std::size_t)batch + r * (std::size_t)classes + (std::size_t)values[2 + r]] / SCALE; if (p < 1e-15) p = 1e-15; total += -std::log(p); }
    return total;
}
