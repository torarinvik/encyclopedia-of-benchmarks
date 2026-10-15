module quadratic_mean;

extern fn double sqrt(double value);
const usz MAX_LENGTH = 64;
const double INVALID_RESULT = -1.0e300;

fn double quadratic_mean(long* values, usz length) @export("quadratic_mean") {
    if (values == null || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double square_sum = 0.0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        double converted = (double)value;
        square_sum += converted * converted;
    }
    return sqrt(square_sum / (double)length);
}
