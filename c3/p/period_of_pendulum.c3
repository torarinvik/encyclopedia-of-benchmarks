module period_of_pendulum;

extern fn double pow(double base, double exponent);
const double PI = 3.141592653589793238462643383279502884;
const double INVALID_RESULT = -1.0e300;

fn double period_of_pendulum(long* values, usz length) @export("period_of_pendulum") {
    if (values == null || length != 1) return INVALID_RESULT;
    long pendulum_length = values[0];
    if (pendulum_length < 0 || pendulum_length > 1000) return INVALID_RESULT;
    double root = pow((double)pendulum_length / 9.80665, 0.5);
    return (2.0 * PI) * root;
}
