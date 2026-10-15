module geometric;

const double INVALID_RESULT = -1.0e300;
extern fn double pow(double base, double exponent);

// Operation 0 tests a geometric sequence; operation 1 computes its mean.
fn double geometric(long* values, usz length) @export("geometric") {
    if (values == null || length < 2) return INVALID_RESULT;
    long operation = values[0];
    usz count = length - 1;
    if (operation == 0) {
        if (count > 16) return INVALID_RESULT;
        for (usz i = 1; i < length; i++) {
            if (values[i] < -100 || values[i] > 100) return INVALID_RESULT;
        }
        if (count == 1) return 1.0;
        if (values[1] == 0) return 0.0;
        double common_ratio = (double)values[2] / (double)values[1];
        for (usz i = 0; i + 1 < count; i++) {
            if (values[i + 1] == 0) return 0.0;
            if ((double)values[i + 2] / (double)values[i + 1] != common_ratio) return 0.0;
        }
        return 1.0;
    }
    if (operation == 1) {
        if (count > 7) return INVALID_RESULT;
        long product = 1;
        for (usz i = 1; i < length; i++) {
            if (values[i] < 0 || values[i] > 100) return INVALID_RESULT;
            product *= values[i];
        }
        return pow((double)product, 1.0 / (double)count);
    }
    return INVALID_RESULT;
}
