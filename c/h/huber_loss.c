/* Mean Huber loss over bounded, fixed-point true/predicted samples. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_PAIRS INT64_C(64)
#define MAX_PARSED_PAIRS INT64_C(65)
#define MAX_SAMPLE INT64_C(1000000000)
#define MAX_DELTA INT64_C(1000000000)
#define MAX_INPUT_LENGTH 133
#define INVALID_RESULT (-1.0e300)

double huber_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t delta_value = values[0], true_count_value = values[1], pred_count_value = values[2];
    if (delta_value < 0 || delta_value > MAX_DELTA ||
        true_count_value < 0 || true_count_value > MAX_PARSED_PAIRS ||
        pred_count_value < 0 || pred_count_value > MAX_PARSED_PAIRS) return INVALID_RESULT;
    if (length != (size_t)(3 + true_count_value + pred_count_value) ||
        true_count_value != pred_count_value || pred_count_value == 0 ||
        true_count_value > MAX_PAIRS) return INVALID_RESULT;

    const size_t count = (size_t)true_count_value;
    for (size_t index = 0; index < count * 2; ++index) {
        if (values[3 + index] < -MAX_SAMPLE || values[3 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }

    const double delta = (double)delta_value / (double)SCALE;
    double total_loss = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double true_value = (double)values[3 + index] / (double)SCALE;
        const double predicted_value = (double)values[3 + count + index] / (double)SCALE;
        const double difference = true_value - predicted_value;
        const double residual = difference < 0.0 ? -difference : difference;
        if (residual <= delta) total_loss += 0.5 * (residual * residual);
        else total_loss += delta * residual - 0.5 * (delta * delta);
    }
    return total_loss / (double)count;
}
