module binary_cross_entropy;
extern fn double log(double value);
const double INVALID_RESULT = -1.0e300;
const double SCALE = 1000000.0;
const double EPSILON = 1.0e-15;
fn double binary_cross_entropy(long* values, usz length) @export("binary_cross_entropy") {
    if (values == null || length < 1 || length > 513) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 0 || count_value > 257 || count_value == 0 || count_value > 256) return INVALID_RESULT;
    if (length != (usz)(1 + 2 * count_value)) return INVALID_RESULT;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index++) {
        long label = values[1 + index];
        long probability = values[1 + count + index];
        if ((label != 0 && label != 1) || probability < 0 || probability > 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (usz index = 0; index < count; index++) {
        double label = (double)values[1 + index];
        double probability = (double)values[1 + count + index] / SCALE;
        if (probability < EPSILON) probability = EPSILON;
        if (probability > 1.0 - EPSILON) probability = 1.0 - EPSILON;
        total -= label * log(probability) + (1.0 - label) * log(1.0 - probability);
    }
    return total / (double)count;
}
