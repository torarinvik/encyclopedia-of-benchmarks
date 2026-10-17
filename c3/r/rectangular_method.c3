module rectangular_method;

extern fn double exp(double value);
extern fn double cos(double value);
extern fn double sin(double value);

const double INVALID_RESULT = -1.0e300;

fn double integrand(double x) {
    return (exp(x) / 2.0) * (cos(x) - sin(x));
}

fn double rectangular_method(long* values, usz length) @export("rectangular_method") {
    if (values == null || length != 4) return INVALID_RESULT;
    long a_quarters = values[0], b_quarters = values[1];
    long intervals = values[2], rule = values[3];
    if (a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
        intervals < 1 || intervals > 64 ||
        (b_quarters - a_quarters) % intervals != 0 ||
        (rule != 0 && rule != 1)) return INVALID_RESULT;

    double a = (double)a_quarters / 4.0;
    double b = (double)b_quarters / 4.0;
    double step = (b - a) / (double)intervals;
    double x = a, total = 0.0;
    for (long i = 0; i < intervals; i++) {
        if (rule == 0) {
            total += integrand(x) * step;
            x += step;
        } else {
            x += step;
            total += integrand(x) * step;
        }
    }
    return total;
}
