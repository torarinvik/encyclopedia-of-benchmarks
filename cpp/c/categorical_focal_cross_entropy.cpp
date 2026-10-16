#include <cmath>
#include <cstddef>
#include <cstdint>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
#define EPSILON 1.0e-15
extern "C" double categorical_focal_cross_entropy(const std::int64_t *values, std::size_t length) noexcept {
    if (values == NULL || length < 2 || length > 2050) return INVALID_RESULT;
    const int64_t batch_value = values[0];
    const int64_t classes_value = values[1];
    if (batch_value < 1 || batch_value > 64 || classes_value < 2 || classes_value > 16) return INVALID_RESULT;
    const size_t batch = (size_t)batch_value;
    const size_t classes = (size_t)classes_value;
    const size_t cells = batch * classes;
    if (length != 2 + 2 * cells) return INVALID_RESULT;
    const size_t labels_start = 2;
    const size_t probabilities_start = 2 + cells;
    for (size_t row = 0; row < batch; ++row) {
        int64_t label_sum = 0;
        int64_t probability_sum = 0;
        for (size_t column = 0; column < classes; ++column) {
            const size_t index = row * classes + column;
            const int64_t label = values[labels_start + index];
            const int64_t probability = values[probabilities_start + index];
            if (label != 0 && label != 1) return INVALID_RESULT;
            if (probability < 0 || probability > 1000000) return INVALID_RESULT;
            label_sum += label;
            probability_sum += probability;
        }
        if (label_sum != 1 || probability_sum != 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (size_t row = 0; row < batch; ++row) {
        double row_loss = 0.0;
        for (size_t column = 0; column < classes; ++column) {
            const size_t index = row * classes + column;
            const double label = (double)values[labels_start + index];
            double probability = (double)values[probabilities_start + index] / SCALE;
            if (probability < EPSILON) probability = EPSILON;
            if (probability > 1.0 - EPSILON) probability = 1.0 - EPSILON;
            const double negative_probability = 1.0 - probability;
            row_loss -= negative_probability * negative_probability * label * log(probability);
        }
        total += row_loss;
    }
    return total / (double)batch;
}
