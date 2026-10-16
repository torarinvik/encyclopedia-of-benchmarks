#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH (1 + 2 * MAX_COUNT)
#define SCALE 1000000.0
#define INVALID_RESULT (-1.0e300)

double kullback_leibler_divergence(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;

    for (size_t i = 0; i < count; ++i) {
        const int64_t target = values[1 + i];
        const int64_t prediction = values[1 + count + i];
        if (target < 0 || target > 1000000 || prediction < 0 || prediction > 1000000 ||
            (target > 0 && prediction == 0)) {
            return INVALID_RESULT;
        }
    }

    double total = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t target_scaled = values[1 + i];
        if (target_scaled == 0) continue;
        const int64_t prediction_scaled = values[1 + count + i];
        const double target = (double)target_scaled / SCALE;
        const double prediction = (double)prediction_scaled / SCALE;
        total += target * log(target / prediction);
    }
    return total;
}
