module thin_lens;

const double INVALID_RESULT = -1.0e300;

fn double thin_lens(long* values, usz length) @export("thin_lens") {
    if (values == null || length != 3) return INVALID_RESULT;
    long operation = values[0], a = values[1], b = values[2];
    if (a < -1000 || a > 1000 || b < -1000 || b > 1000) return INVALID_RESULT;
    if (operation == 0) {
        if (a == 0 || b == 0 || a == b) return INVALID_RESULT;
        double f = (double)a, u = (double)b;
        return 1.0 / ((1.0 / f) - (1.0 / u));
    }
    if (operation == 1) {
        if (b == 0) return INVALID_RESULT;
        return (double)a / (double)b;
    }
    if (operation == 2) {
        if (b != 0) return INVALID_RESULT;
        return a > 0 ? 1.0 : 0.0;
    }
    return INVALID_RESULT;
}
