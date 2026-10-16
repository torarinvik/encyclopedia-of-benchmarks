module exponential_dist;

extern fn double pow(double base, double exponent);

const long MAX_RATE_MICRO = 1000000000;
const double INVALID_RESULT = -1.0e300;

fn double exponential_dist_impl(long* values, usz length) {
    if (values == null || length != 2) return INVALID_RESULT;
    long operation = values[0], rate_micro = values[1];
    if (operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > MAX_RATE_MICRO)
        return INVALID_RESULT;
    double rate = (double)rate_micro / 1000000.0;
    if (operation == 1) return 1.0 / pow(rate, 2.0);
    return 1.0 / rate;
}

fn double exponential_dist(long* values, usz length) @export("exponential_dist") {
    return exponential_dist_impl(values, length);
}
