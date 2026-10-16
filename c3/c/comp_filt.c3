module comp_filt;

const long MAX_SAMPLES = 32;
const long SCALE = 1000000;
const long MAX_SIGNAL_MICRO = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double comp_filt(long* values, usz length) @export("comp_filt") {
    if (values == null || length < 6 || length > 68) return INVALID_RESULT;
    long alpha_ppm = values[0];
    long delta_t_micro = values[1];
    long count_value = values[2];
    long output_index_value = values[3];
    if (alpha_ppm < 0 || alpha_ppm > SCALE || delta_t_micro < 0 || delta_t_micro > SCALE ||
        count_value < 1 || count_value > MAX_SAMPLES || output_index_value < 0 || output_index_value > count_value)
        return INVALID_RESULT;
    usz count = (usz)count_value;
    usz output_index = (usz)output_index_value;
    if (length != 4 + 2 * count) return INVALID_RESULT;
    for (usz i = 0; i < count; i++) {
        long rate = values[4 + i];
        long reference = values[4 + count + i];
        if (rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO ||
            reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO) return INVALID_RESULT;
    }
    double alpha = (double)alpha_ppm / (double)SCALE;
    double delta_t = (double)delta_t_micro / (double)SCALE;
    double theta = (double)values[4 + count] / (double)SCALE;
    for (usz i = 0; i < output_index; i++) {
        double rate = (double)values[4 + i] / (double)SCALE;
        double reference = (double)values[4 + count + i] / (double)SCALE;
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference;
    }
    return theta;
}
