#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MIN_PROBABILITY_MICRO INT64_C(1)
#define MAX_PROBABILITY_MICRO INT64_C(999999)
#define MIN_RATIO_MICRO INT64_C(1000)
#define MAX_RATIO_MICRO INT64_C(100000000)
#define MAX_INPUT_LENGTH 3
#define INVALID_RESULT (-1.0e300)

double kelly_criterion(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t probability_micro = values[0], ratio_micro = values[1];
    if (probability_micro < MIN_PROBABILITY_MICRO || probability_micro > MAX_PROBABILITY_MICRO
            || ratio_micro < MIN_RATIO_MICRO || ratio_micro > MAX_RATIO_MICRO) return INVALID_RESULT;
    const double win_probability = (double)probability_micro / (double)SCALE;
    const double win_loss_ratio = (double)ratio_micro / (double)SCALE;
    const double loss_probability = 1.0 - win_probability;
    return (win_probability * win_loss_ratio - loss_probability) / win_loss_ratio;
}
