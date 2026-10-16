module elu;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;
const double ALPHA_MAX = 1000000.0;

fn double elu(double x, double alpha) @export("elu") {
    if (x != x || alpha != alpha || x < -100.0 || x > 100.0 ||
        alpha < -ALPHA_MAX || alpha > ALPHA_MAX) return INVALID_RESULT;
    return x < 0.0 ? alpha * (exp(x) - 1.0) : x;
}
