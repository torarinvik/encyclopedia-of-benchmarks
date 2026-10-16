module midpoint_integral_method;

extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);
extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;

fn double integrand(long function_id, double x) {
    if (function_id == 0) return sqrt(x) + log(x);
    if (function_id == 1) return exp(-x) * (4.0 - pow(x, 2.0));
    if (function_id == 2) return sqrt(2.0 * pow(x, 3.0) + 3.0);
    if (function_id == 3) return x + log(2.0 * x + 1.0);
    return INVALID_RESULT;
}

fn double midpoint_integral_method(long* values, usz length) @export("midpoint_integral_method") {
    if (values == null || length != 4) return INVALID_RESULT;
    long function_id = values[0], intervals = values[1];
    long a_milli = values[2], b_milli = values[3];
    if (function_id < 0 || function_id > 3 || intervals < 2 || intervals > 64 || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000) return INVALID_RESULT;
    double a = (double)a_milli / 1000.0;
    double b = (double)b_milli / 1000.0;
    double h = (b - a) / (double)intervals;
    double xi = a, sum = 0.0;
    for (long i = 0; i < intervals; i++) {
        sum += integrand(function_id, xi + h / 2.0);
        xi += h;
    }
    return sum * h;
}
