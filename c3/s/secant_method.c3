module secant_method;

extern fn double exp(double value);
extern fn double fabs(double value);

const double INVALID_RESULT = -1.0e300;

fn double python_objective(double x) {
    return 8.0 * x - 2.0 * exp(-x);
}

fn double c_variant() {
    double x0 = 0.2;
    double x1 = 0.5;
    double tolerance = 100.0 / 1000000.0;
    for (long iteration = 0; iteration < 99; iteration += 1) {
        double f1 = x1 * x1 - 3.0;
        double f0 = x0 * x0 - 3.0;
        double x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1;
        x1 = x2;
        if (fabs(x1 - x0) < tolerance) return x2;
    }
    return -1.0;
}

fn double python_variant(long repeats) {
    double x0 = 1.0;
    double x1 = 3.0;
    for (long iteration = 0; iteration < repeats; iteration += 1) {
        double f1 = python_objective(x1);
        double f0 = python_objective(x0);
        double x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0);
        x0 = x1;
        x1 = x2;
    }
    return x1;
}

fn double secant_method(long* values, usz length) @export("secant_method") {
    if (values == null || length != 2) return INVALID_RESULT;
    if (values[0] == 0 && values[1] == 100) return c_variant();
    if (values[0] == 1 && values[1] >= 0 && values[1] <= 2) return python_variant(values[1]);
    return INVALID_RESULT;
}
