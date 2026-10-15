module linear_regression_gradient_descent;

const usz MAX_OBSERVATIONS = 64;
const long MAX_EPOCHS = 10000;
const double INVALID_RESULT = -1.0e300;

fn double linear_regression_gradient_descent(long* values, usz length) @export("linear_regression_gradient_descent") {
    if (values == null || length < 7 || length > 3 + 2 * MAX_OBSERVATIONS || length % 2 == 0) return INVALID_RESULT;
    long count = values[0];
    long rate_microunits = values[1];
    long epochs = values[2];
    if (count < 2 || count > 64 || length != 3 + 2 * (usz)count ||
        rate_microunits < 1 || rate_microunits > 1000 || epochs < 1 || epochs > MAX_EPOCHS) return INVALID_RESULT;
    for (usz index = 0; index < (usz)count; index++) {
        long x = values[3 + 2 * index];
        long y = values[4 + 2 * index];
        if (x < -10 || x > 10 || y < -100 || y > 100) return INVALID_RESULT;
    }

    double alpha = (double)rate_microunits / 1000000.0;
    double scale = alpha / (double)count;
    double slope = 0.0;
    double intercept = 0.0;
    for (long epoch = 0; epoch < epochs; epoch++) {
        double slope_gradient = 0.0;
        double intercept_gradient = 0.0;
        for (usz index = 0; index < (usz)count; index++) {
            double x = (double)values[3 + 2 * index];
            double y = (double)values[4 + 2 * index];
            double error = slope * x + intercept - y;
            slope_gradient += error * x;
            intercept_gradient += error;
        }
        slope -= scale * slope_gradient;
        intercept -= scale * intercept_gradient;
    }
    return slope;
}
