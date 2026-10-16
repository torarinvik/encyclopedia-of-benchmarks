#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TIME 32
#define MAX_CLASSES 16
#define MAX_TARGET 16
#define MAX_INPUT_LENGTH (3 + MAX_TARGET + MAX_TIME * MAX_CLASSES)
#define MAX_STATES (2 * MAX_TARGET + 1)
#define INVALID_RESULT (-1.0e300)

static double logaddexp_value(double left, double right)
{
    if (isinf(left) && left < 0.0) return right;
    if (isinf(right) && right < 0.0) return left;
    const double larger = left > right ? left : right;
    const double smaller = left > right ? right : left;
    return larger + log1p(exp(smaller - larger));
}

double connectionist_temporal_classification_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t time_value = values[0], classes_value = values[1], target_value = values[2];
    if (time_value < 1 || time_value > MAX_TIME || classes_value < 2 || classes_value > MAX_CLASSES ||
        target_value < 1 || target_value > MAX_TARGET) return INVALID_RESULT;
    const size_t time = (size_t)time_value, classes = (size_t)classes_value, target_length = (size_t)target_value;
    if (length != 3 + target_length + time * classes) return INVALID_RESULT;
    size_t repeated = 0;
    for (size_t i = 0; i < target_length; ++i) {
        const int64_t target = values[3 + i];
        if (target < 1 || (size_t)target >= classes) return INVALID_RESULT;
        if (i > 0 && target == values[3 + i - 1]) ++repeated;
    }
    if (time < target_length + repeated) return INVALID_RESULT;
    const size_t probability_base = 3 + target_length;
    for (size_t t = 0; t < time; ++t) {
        int64_t sum = 0;
        for (size_t c = 0; c < classes; ++c) {
            const int64_t p = values[probability_base + t * classes + c];
            if (p < 1 || p > 1000000) return INVALID_RESULT;
            sum += p;
        }
        if (sum != 1000000) return INVALID_RESULT;
    }

    const size_t states = 2 * target_length + 1;
    int64_t extended[MAX_STATES];
    double previous[MAX_STATES], current[MAX_STATES];
    for (size_t s = 0; s < states; ++s) {
        extended[s] = (s % 2 == 0) ? 0 : values[3 + s / 2];
        previous[s] = -INFINITY;
    }
    previous[0] = log((double)values[probability_base] / 1000000.0);
    previous[1] = log((double)values[probability_base + (size_t)extended[1]] / 1000000.0);
    for (size_t t = 1; t < time; ++t) {
        for (size_t s = 0; s < states; ++s) {
            double incoming = previous[s];
            if (s > 0) incoming = logaddexp_value(incoming, previous[s - 1]);
            if (s > 1 && extended[s] != extended[s - 2])
                incoming = logaddexp_value(incoming, previous[s - 2]);
            const double probability = (double)values[probability_base + t * classes + (size_t)extended[s]] / 1000000.0;
            current[s] = incoming + log(probability);
        }
        for (size_t s = 0; s < states; ++s) previous[s] = current[s];
    }
    return -logaddexp_value(previous[states - 1], previous[states - 2]);
}
