#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 256
#define MAX_INPUT_LENGTH (1 + 2 * MAX_COUNT)
#define PREDICTION_SCALE 1000000.0
#define INVALID_RESULT (-1.0e300)

double hinge_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;

    double total = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t label = values[1 + index];
        const int64_t score_scaled = values[1 + count + index];
        if ((label != -1 && label != 1) || score_scaled < -1000000 || score_scaled > 1000000)
            return INVALID_RESULT;
        const double prediction = (double)score_scaled / PREDICTION_SCALE;
        const double loss = 1.0 - (double)label * prediction;
        if (loss > 0.0) total += loss;
    }
    return total / (double)count;
}
