module geometric_mean;

extern fn double pow(double base, double exponent);
extern fn double fabs(double value);
extern fn double floor(double value);

const long MAX_LENGTH = 6;
const long MAX_ABS_VALUE = 100;
const double INVALID_RESULT = -1.0e300;

fn double geometric_mean(long* values, usz length) @export("geometric_mean") {
    if (length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    long product = 1;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return INVALID_RESULT;
        product *= value;
    }
    if (product < 0 && length % 2 == 0) return INVALID_RESULT;
    double root = pow(fabs((double)product), 1.0 / (double)length);
    double rounded = floor(root + 0.5);
    long rounded_power = 1;
    for (usz i = 0; i < length; i++) rounded_power *= (long)rounded;
    if ((product >= 0 && rounded_power == product)
        || (product < 0 && length % 2 == 1 && -rounded_power == product)) root = rounded;
    if (product < 0) root = -root;
    return root;
}
