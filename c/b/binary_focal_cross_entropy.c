#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
#define EPSILON 1.0e-15
double binary_focal_cross_entropy(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 513) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > 257) return INVALID_RESULT;
    if (count_value == 0 || count_value > 256 || length != (size_t)(1 + 2 * count_value)) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index) {
        const int64_t label = values[1 + index];
        const int64_t probability = values[1 + count + index];
        if ((label != 0 && label != 1) || probability < 0 || probability > 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double label = (double)values[1 + index];
        double probability = (double)values[1 + count + index] / SCALE;
        if (probability < EPSILON) probability = EPSILON;
        if (probability > 1.0 - EPSILON) probability = 1.0 - EPSILON;
        const double negative_probability = 1.0 - probability;
        total -= 0.25 * negative_probability * negative_probability * label * log(probability) +
                 0.75 * probability * probability * (1.0 - label) * log(negative_probability);
    }
    return total / (double)count;
}
