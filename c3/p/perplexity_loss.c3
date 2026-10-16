module perplexity_loss;
import "math";

const usz MAX_BATCH = 8, MAX_TIME = 16, MAX_VOCAB = 16;
const usz MAX_INPUT_LENGTH = 3 + MAX_BATCH * MAX_TIME * (MAX_VOCAB + 1);
const double INVALID_RESULT = -1.0e300;

fn double perplexity_loss(long* values, usz length) @export("perplexity_loss") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long batch_value = values[0], time_value = values[1], vocab_value = values[2];
    if (batch_value < 1 || batch_value > MAX_BATCH || time_value < 1 || time_value > MAX_TIME || vocab_value < 2 || vocab_value > MAX_VOCAB) return INVALID_RESULT;
    usz batch = (usz)batch_value, time = (usz)time_value, vocab = (usz)vocab_value;
    usz tokens = batch * time, probability_base = 3 + tokens;
    if (length != probability_base + tokens * vocab) return INVALID_RESULT;
    for (usz row = 0; row < tokens; row++) {
        long label = values[3 + row];
        if (label < 0 || (usz)label >= vocab) return INVALID_RESULT;
        long row_sum = 0;
        for (usz c = 0; c < vocab; c++) {
            long p = values[probability_base + row * vocab + c];
            if (p < 0 || p > 1000000) return INVALID_RESULT;
            row_sum += p;
        }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    double batch_total = 0.0;
    for (usz sentence = 0; sentence < batch; sentence++) {
        double log_total = 0.0;
        for (usz step = 0; step < time; step++) {
            usz row = sentence * time + step;
            usz label = (usz)values[3 + row];
            double p = (double)values[probability_base + row * vocab + label] / 1000000.0;
            if (p < 1e-7) p = 1e-7;
            if (p > 1.0) p = 1.0;
            log_total += math.log(p);
        }
        batch_total += math.exp(-(log_total / (double)time));
    }
    return batch_total / (double)batch;
}
