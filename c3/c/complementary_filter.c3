module complementary_filter;

const long MAX_SAMPLES = 32;
const long SCALE = 1000000;
const long MAX_SIGNAL_MICRO = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double complementary_filter(long* values, usz length) @export("complementary_filter") {
    if (values == null || length < 2) return INVALID_RESULT;
    long coefficient_ppm = values[0];
    long sample_count_value = values[1];
    if (coefficient_ppm < 1 || coefficient_ppm >= SCALE || sample_count_value < 1 || sample_count_value > MAX_SAMPLES)
        return INVALID_RESULT;
    usz sample_count = (usz)sample_count_value;
    if (length != 2 + 3 * sample_count) return INVALID_RESULT;
    for (usz sample = 0; sample < sample_count; sample++) {
        long rate = values[2 + 3 * sample];
        long reference = values[3 + 3 * sample];
        long elapsed = values[4 + 3 * sample];
        if (rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO ||
            reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO || elapsed < 1 || elapsed > SCALE)
            return INVALID_RESULT;
    }
    double coefficient = (double)coefficient_ppm / (double)SCALE;
    double value = 0.0;
    for (usz sample = 0; sample < sample_count; sample++) {
        double rate = (double)values[2 + 3 * sample] / (double)SCALE;
        double reference = (double)values[3 + 3 * sample] / (double)SCALE;
        double elapsed = (double)values[4 + 3 * sample] / (double)SCALE;
        if (sample == 0) value = reference;
        else value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference;
    }
    return value;
}
