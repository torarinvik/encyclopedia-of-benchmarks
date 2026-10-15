module gaussian_error_linear_unit;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;

fn double gaussian_error_linear_unit(double x) @export("gaussian_error_linear_unit") {
    if (x != x || x < -100.0 || x > 100.0) return INVALID_RESULT;
    return x * (1.0 / (1.0 + exp(-1.702 * x)));
}
