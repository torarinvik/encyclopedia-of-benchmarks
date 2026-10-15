module harmonic_mean;

const usz MAX_LENGTH = 64;
const double INVALID_RESULT = -1.0e300;

fn double harmonic_mean(long* values, usz length) @export("harmonic_mean") {
    if (values == null || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double reciprocal_sum = 0.0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 1 || value > 1000) return INVALID_RESULT;
        reciprocal_sum += 1.0 / (double)value;
    }
    return (double)length / reciprocal_sum;
}
