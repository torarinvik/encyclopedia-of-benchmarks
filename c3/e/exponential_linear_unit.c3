module exponential_linear_unit;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;
const double ALPHA_MAX = 1000000.0;

fn double exponential_linear_unit(double x, double alpha) @export("exponential_linear_unit") {
    if (x != x || alpha != alpha || x < -100.0 || x > 100.0 || alpha < -ALPHA_MAX || alpha > ALPHA_MAX) {
        return INVALID_RESULT;
    }
    return x < 0.0 ? x * (alpha * (exp(x) - 1.0)) : x;
}
