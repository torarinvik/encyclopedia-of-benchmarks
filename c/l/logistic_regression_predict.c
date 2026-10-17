#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 63
#define MAX_FEATURES 32
#define MAX_INPUT_LENGTH 2051
int64_t logistic_regression_predict(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows = values[0], features = values[1];
    if (rows < 1 || rows > MAX_ROWS || features < 1 || features > MAX_FEATURES ||
        length != 2u + (size_t)rows * (size_t)features + (size_t)features) return -1;
    const size_t theta_offset = 2u + (size_t)rows * (size_t)features;
    for (size_t i = 0; i < (size_t)rows * (size_t)features + (size_t)features; ++i) {
        const int64_t value = values[2 + i];
        if (value < -1000 || value > 1000) return -1;
    }
    uint64_t mask = 0;
    for (size_t row = 0; row < (size_t)rows; ++row) {
        int64_t score = 0;
        for (size_t feature = 0; feature < (size_t)features; ++feature)
            score += values[2 + row * (size_t)features + feature] * values[theta_offset + feature];
        if (score >= 0) mask |= UINT64_C(1) << row;
    }
    return (int64_t)mask;
}
