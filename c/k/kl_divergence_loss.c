#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_COUNT)
#define INVALID_RESULT (-1.0e300)

double kl_divergence_loss(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t actual_count_value = input[0];
    const int64_t predicted_count_value = input[1];
    if (actual_count_value < 0 || actual_count_value > MAX_COUNT ||
        predicted_count_value < 0 || predicted_count_value > MAX_COUNT) return INVALID_RESULT;
    const size_t actual_count = (size_t)actual_count_value;
    const size_t predicted_count = (size_t)predicted_count_value;
    if (length != 2 + actual_count + predicted_count) return INVALID_RESULT;

    for (size_t i = 0; i < actual_count; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1000000) return INVALID_RESULT;
    for (size_t i = 0; i < predicted_count; ++i)
        if (input[2 + actual_count + i] < 0 || input[2 + actual_count + i] > 1000000) return INVALID_RESULT;

    const size_t paired_count = actual_count < predicted_count ? actual_count : predicted_count;
    double total = 0.0;
    for (size_t i = 0; i < paired_count; ++i) {
        const double actual = (double)input[2 + i] / 1000000.0 + 1e-5;
        const double predicted = (double)input[2 + actual_count + i] / 1000000.0 + 1e-5;
        total += actual * log(actual / predicted);
    }
    return total;
}
