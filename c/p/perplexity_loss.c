#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_BATCH 8
#define MAX_TIME 16
#define MAX_VOCAB 16
#define MAX_INPUT_LENGTH (3 + MAX_BATCH * MAX_TIME * (MAX_VOCAB + 1))
#define INVALID_RESULT (-1.0e300)

double perplexity_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t batch_value = values[0], time_value = values[1], vocab_value = values[2];
    if (batch_value < 1 || batch_value > MAX_BATCH || time_value < 1 || time_value > MAX_TIME ||
        vocab_value < 2 || vocab_value > MAX_VOCAB) return INVALID_RESULT;
    const size_t batch = (size_t)batch_value, time = (size_t)time_value, vocab = (size_t)vocab_value;
    const size_t tokens = batch * time, probability_count = tokens * vocab;
    if (length != 3 + tokens + probability_count) return INVALID_RESULT;
    const size_t probability_base = 3 + tokens;
    for (size_t row = 0; row < tokens; ++row) {
        const int64_t label = values[3 + row];
        if (label < 0 || (size_t)label >= vocab) return INVALID_RESULT;
        int64_t row_sum = 0;
        for (size_t c = 0; c < vocab; ++c) {
            const int64_t probability = values[probability_base + row * vocab + c];
            if (probability < 0 || probability > 1000000) return INVALID_RESULT;
            row_sum += probability;
        }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    double batch_total = 0.0;
    for (size_t sentence = 0; sentence < batch; ++sentence) {
        double log_total = 0.0;
        for (size_t step = 0; step < time; ++step) {
            const size_t row = sentence * time + step;
            const size_t label = (size_t)values[3 + row];
            double probability = (double)values[probability_base + row * vocab + label] / 1000000.0;
            if (probability < 1e-7) probability = 1e-7;
            if (probability > 1.0) probability = 1.0;
            log_total += log(probability);
        }
        batch_total += exp(-(log_total / (double)time));
    }
    return batch_total / (double)batch;
}
