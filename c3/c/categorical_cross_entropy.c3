module categorical_cross_entropy;
extern fn double log(double value);
const double INVALID_RESULT = -1.0e300;
const double SCALE = 1000000.0;
const double EPSILON = 1.0e-15;
fn double categorical_cross_entropy(long* values, usz length) @export("categorical_cross_entropy") {
    if (values == null || length < 2 || length > 2050) return INVALID_RESULT;
    long batch_value = values[0];
    long classes_value = values[1];
    if (batch_value < 1 || batch_value > 64 || classes_value < 2 || classes_value > 16) return INVALID_RESULT;
    usz batch = (usz)batch_value;
    usz classes = (usz)classes_value;
    usz cells = batch * classes;
    if (length != 2 + 2 * cells) return INVALID_RESULT;
    usz labels_start = 2;
    usz probabilities_start = 2 + cells;
    for (usz row = 0; row < batch; row++) {
        long label_sum = 0;
        long probability_sum = 0;
        for (usz column = 0; column < classes; column++) {
            usz index = row * classes + column;
            long label = values[labels_start + index];
            long probability = values[probabilities_start + index];
            if (label != 0 && label != 1) return INVALID_RESULT;
            if (probability < 0 || probability > 1000000) return INVALID_RESULT;
            label_sum += label;
            probability_sum += probability;
        }
        if (label_sum != 1 || probability_sum != 1000000) return INVALID_RESULT;
    }
    double total = 0.0;
    for (usz row = 0; row < batch; row++) {
        double row_loss = 0.0;
        for (usz column = 0; column < classes; column++) {
            usz index = row * classes + column;
            double label = (double)values[labels_start + index];
            double probability = (double)values[probabilities_start + index] / SCALE;
            if (probability < EPSILON) probability = EPSILON;
            if (probability > 1.0) probability = 1.0;
            row_loss -= label * log(probability);
        }
        total += row_loss;
    }
    return total;
}
