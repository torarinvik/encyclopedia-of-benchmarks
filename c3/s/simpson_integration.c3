module simpson_integration;

extern fn double exp(double value);
extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;
const long MAX_ENDPOINT_MICRO = 10000000;

fn double integrand(double x) {
    return exp(-x) * (4.0 - pow(x, 2.0));
}

fn double simpson_integration(long* values, usz length) @export("simpson_integration") {
    if (values == null || length != 3) return INVALID_RESULT;
    long intervals = values[0], a_micro = values[1], b_micro = values[2];
    if (intervals < 2 || intervals > 128 || intervals % 2 != 0 ||
        a_micro < -MAX_ENDPOINT_MICRO || a_micro > MAX_ENDPOINT_MICRO ||
        b_micro < -MAX_ENDPOINT_MICRO || b_micro > MAX_ENDPOINT_MICRO || a_micro > b_micro) {
        return INVALID_RESULT;
    }
    double a = (double)a_micro / 1000000.0;
    double b = (double)b_micro / 1000000.0;
    if (a == b) return 0.0;
    double h = (b - a) / (double)intervals;
    double xi = a, total = 0.0;
    for (long i = 0; i <= intervals; i++) {
        double sample = integrand(xi);
        if (i == 0 || i == intervals) total += sample;
        else if (i % 2 != 0) total += 4.0 * sample;
        else total += 2.0 * sample;
        xi += h;
    }
    return (h / 3.0) * total;
}
