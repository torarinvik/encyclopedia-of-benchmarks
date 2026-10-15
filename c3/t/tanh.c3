module tanh;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;

fn double tanh(double x) @export("tanh") {
    if (x != x || x < -10.0 || x > 10.0) return INVALID_RESULT;
    return (2.0 / (1.0 + exp(-2.0 * x))) - 1.0;
}
