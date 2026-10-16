module huber_loss;

const long SCALE = 1000000;
const long MAX_PAIRS = 64;
const long MAX_PARSED_PAIRS = 65;
const long MAX_SAMPLE = 1000000000;
const long MAX_DELTA = 1000000000;
const usz MAX_INPUT_LENGTH = 133;
const double INVALID_RESULT = -1.0e300;

fn double huber_loss_impl(long* values, usz length) {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long delta_value = values[0], true_count = values[1], pred_count = values[2];
    if (delta_value < 0 || delta_value > MAX_DELTA ||
        true_count < 0 || true_count > MAX_PARSED_PAIRS ||
        pred_count < 0 || pred_count > MAX_PARSED_PAIRS) return INVALID_RESULT;
    if (length != (usz)(3 + true_count + pred_count) || true_count != pred_count ||
        pred_count == 0 || true_count > MAX_PAIRS) return INVALID_RESULT;

    for (usz index = 0; index < (usz)(2 * true_count); index++) {
        if (values[3 + index] < -MAX_SAMPLE || values[3 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }
    double delta = (double)delta_value / (double)SCALE;
    double total_loss = 0.0;
    for (usz index = 0; index < (usz)true_count; index++) {
        double true_value = (double)values[3 + index] / (double)SCALE;
        double predicted_value = (double)values[3 + (usz)true_count + index] / (double)SCALE;
        double difference = true_value - predicted_value;
        double residual = difference;
        if (residual < 0.0) residual = -residual;
        if (residual <= delta) total_loss += 0.5 * (residual * residual);
        else total_loss += delta * residual - 0.5 * (delta * delta);
    }
    return total_loss / (double)true_count;
}

fn double huber_loss(long* values, usz length) @export("huber_loss") {
    return huber_loss_impl(values, length);
}
