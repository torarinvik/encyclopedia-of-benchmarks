module swish;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;

fn double swish(double x) @export("swish") {
    if (x != x || x < -100.0 || x > 100.0) return INVALID_RESULT;
    double scaled = 1.0 * x;
    return x * (1.0 / (1.0 + exp(-scaled)));
}
