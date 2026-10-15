module gaussian_error_linear_unit_tanh;

extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;
const double PI_VALUE = 3.14159265358979323846264338327950288;
const double E_VALUE = 2.71828182845904523536028747135266250;

// Preserve the pinned Rust tanh-GELU operation order.
fn double gaussian_error_linear_unit_tanh(double x) @export("gaussian_error_linear_unit_tanh") {
    if (x != x || x < -100.0 || x > 100.0) return INVALID_RESULT;
    double scale = pow(2.0 / PI_VALUE, 0.5);
    double z = scale * (x + 0.044715 * pow(x, 3.0));
    double tanh_value = 2.0 / (1.0 + pow(E_VALUE, -2.0 * z)) - 1.0;
    return x * 0.5 * (1.0 + tanh_value);
}
