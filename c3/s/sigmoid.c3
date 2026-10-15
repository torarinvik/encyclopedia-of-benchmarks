module sigmoid;

extern fn double exp(double value);

const double INVALID_RESULT = -1.0e300;

fn double sigmoid(double x) @export("sigmoid") {
    if (x != x || x < -20.0 || x > 20.0) return INVALID_RESULT;
    return 1.0 / (1.0 + exp(-x));
}
