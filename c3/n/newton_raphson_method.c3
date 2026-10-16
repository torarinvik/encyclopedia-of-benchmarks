module newton_raphson_method;

extern fn double pow(double base, double exponent);
extern fn double fabs(double value);
const double INVALID_RESULT = -1.0e300;

fn double equation(double x) { return pow(x, 3.0) - (4.0 * x) - 9.0; }
fn double derivative(double x) { return 3.0 * pow(x, 2.0) - 4.0; }

fn double newton_raphson_method(long* values, usz length) @export("newton_raphson_method") {
    if (values == null || length != 2) return INVALID_RESULT;
    long initial_milli = values[0];
    long iteration_limit = values[1];
    if (initial_milli < 2000 || initial_milli > 4000 || iteration_limit < 1 || iteration_limit > 32) {
        return INVALID_RESULT;
    }
    double c = (double)initial_milli / 1000.0;
    double z = c;
    for (long iteration = 0; iteration < iteration_limit; iteration++) {
        double m = equation(c);
        double n = derivative(c);
        z = c - (m / n);
        c = z;
        if (fabs(m) < 1e-10) break;
    }
    return z;
}
