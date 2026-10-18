module linear_discriminant_analysis;

extern fn double log(double value);
const usz MAX_CLASSES = 4;
const usz MAX_SAMPLES = 16;
const usz MAX_INPUT = 22;
const double MIN_MARGIN = 1e-8;

fn bool exact_integer(double value, double minimum, double maximum) {
    if (value != value || value < minimum || value > maximum) return false;
    return (double)(long)value == value;
}

fn long linear_discriminant_analysis(double* input, usz input_length,
        double* output, usz capacity) @export("linear_discriminant_analysis") {
    if (input == null || input_length == 0 || input_length > MAX_INPUT) return -1L;
    if (!exact_integer(input[0], 2.0, 4.0)) return -1L;
    usz class_count = (usz)(long)input[0];
    if (input_length < 1 + class_count) return -1L;
    usz[MAX_CLASSES] counts = zeroed;
    usz total_count = 0;
    for (usz k = 0; k < class_count; k++) {
        if (!exact_integer(input[1 + k], 2.0, 6.0)) return -1L;
        counts[k] = (usz)(long)input[1 + k];
        total_count += counts[k];
    }
    if (total_count > MAX_SAMPLES || input_length != 1 + class_count + total_count) return -1L;

    double[MAX_CLASSES * 6] groups = zeroed;
    double[MAX_CLASSES] means = zeroed;
    usz offset = 1 + class_count;
    for (usz k = 0; k < class_count; k++) {
        double sum = 0.0;
        for (usz j = 0; j < counts[k]; j++) {
            double x = input[offset++];
            if (!exact_integer(x, -32.0, 32.0)) return -1L;
            groups[k * 6 + j] = x;
            sum += x;
        }
        means[k] = sum / (double)counts[k];
        if (!exact_integer(means[k], -32.0, 32.0)) return -1L;
    }
    double squared_sum = 0.0;
    for (usz k = 0; k < class_count; k++) for (usz j = 0; j < counts[k]; j++) {
        double delta = groups[k * 6 + j] - means[k];
        squared_sum += delta * delta;
    }
    double variance = (1.0 / (double)(total_count - class_count)) * squared_sum;
    if (!(variance > 0.0) || variance != variance) return -1L;
    double[MAX_CLASSES] priors;
    for (usz k = 0; k < class_count; k++) priors[k] = (double)counts[k] / (double)total_count;

    double[MAX_SAMPLES] staged = zeroed;
    usz n = 0;
    for (usz group = 0; group < class_count; group++) for (usz j = 0; j < counts[group]; j++) {
        double x = groups[group * 6 + j];
        double best = -1e308, second = -1e308;
        usz winner = 0;
        for (usz k = 0; k < class_count; k++) {
            double score = x * (means[k] / variance) - (means[k] * means[k] / (2.0 * variance)) + log(priors[k]);
            if (score > best) { second = best; best = score; winner = k; }
            else if (score > second) second = score;
        }
        if (best - second < MIN_MARGIN) return -1L;
        staged[n++] = (double)winner;
    }
    if (output == null || capacity < n) return -2L;
    for (usz i = 0; i < n; i++) output[i] = staged[i];
    return (long)n;
}
