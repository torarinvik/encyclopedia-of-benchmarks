module kl_divergence_loss;

extern fn double log(double value);
const usz MAX_COUNT = 64;
const double SCALE = 1000000.0;
const double EPSILON = 1e-5;
const double INVALID_RESULT = -1.0e300;

fn double kl_divergence_loss(long* input, usz length) @export("kl_divergence_loss") {
    if (input == null || length < 2 || length > 130) return INVALID_RESULT;
    long actual_count_value = input[0];
    long predicted_count_value = input[1];
    if (actual_count_value < 0 || actual_count_value > 64 || predicted_count_value < 0 || predicted_count_value > 64)
        return INVALID_RESULT;
    usz actual_count = (usz)actual_count_value;
    usz predicted_count = (usz)predicted_count_value;
    if (length != 2 + actual_count + predicted_count) return INVALID_RESULT;
    for (usz i = 0; i < actual_count; i++)
        if (input[2 + i] < 0 || input[2 + i] > 1000000) return INVALID_RESULT;
    for (usz i = 0; i < predicted_count; i++)
        if (input[2 + actual_count + i] < 0 || input[2 + actual_count + i] > 1000000) return INVALID_RESULT;

    usz paired_count = actual_count < predicted_count ? actual_count : predicted_count;
    double total = 0.0;
    for (usz i = 0; i < paired_count; i++) {
        double actual = (double)input[2 + i] / SCALE + EPSILON;
        double predicted = (double)input[2 + actual_count + i] / SCALE + EPSILON;
        total += actual * log(actual / predicted);
    }
    return total;
}
