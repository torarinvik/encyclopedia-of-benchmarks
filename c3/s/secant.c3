module secant;

extern fn double fabs(double value);

const double INVALID_RESULT = -1.0e300;

fn double objective(double x) { return x * x - 3.0; }

fn double secant(long* values, usz length) @export("secant") {
    if (values == null || length != 5) return INVALID_RESULT;
    if (values[0] != 0 || values[1] < 1000000 || values[1] > 1500000 ||
        values[2] < 1600000 || values[2] > 2000000 || values[1] >= values[2] ||
        values[3] < 1 || values[3] > 100000 || values[4] < 0 || values[4] > 32) return INVALID_RESULT;
    double x0 = (double)values[1] / 1000000.0;
    double x1 = (double)values[2] / 1000000.0;
    double tolerance = (double)values[3] / 1000000000.0;
    long max_updates = values[4];
    long update = 0;
    while (update <= max_updates) {
        double f1 = objective(x1);
        if (fabs(f1) <= tolerance) return x1;
        if (update == max_updates) break;
        double f0 = objective(x0);
        double denominator = f1 - f0;
        if (denominator == 0.0) return INVALID_RESULT;
        double x2 = x1 - f1 * (x1 - x0) / denominator;
        x0 = x1;
        x1 = x2;
        update += 1;
    }
    return INVALID_RESULT;
}
