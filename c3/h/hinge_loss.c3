module hinge_loss;

const usz MAX_INPUT_LENGTH = 513;
const long MAX_COUNT = 256;
const double PREDICTION_SCALE = 1000000.0;
const double INVALID_RESULT = -1.0e300;

fn double hinge_loss(long* values, usz length) @export("hinge_loss") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;

    double total = 0.0;
    for (usz index = 0; index < count; index++) {
        long label = values[1 + index];
        long score_scaled = values[1 + count + index];
        if ((label != -1 && label != 1) || score_scaled < -1000000 || score_scaled > 1000000)
            return INVALID_RESULT;
        double prediction = (double)score_scaled / PREDICTION_SCALE;
        double loss = 1.0 - (double)label * prediction;
        if (loss > 0.0) total += loss;
    }
    return total / (double)count;
}
