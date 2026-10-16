module maclaurin_series;

extern fn double pow(double base, double exponent);
extern fn double floor(double value);

const double INVALID_RESULT = -1.0e300;
const double PI = 3.14159265358979323846264338327950288;

fn double factorial(long n) {
    double result = 1.0;
    for (long i = 2; i <= n; i++) result *= (double)i;
    return result;
}

fn double maclaurin_series(long* values, usz length) @export("maclaurin_series") {
    if (values == null || length != 3) return INVALID_RESULT;
    long mode = values[0], theta_input = values[1], accuracy = values[2];
    if ((mode != 0 && mode != 1) || theta_input < -10 || theta_input > 10 || accuracy < 1 || accuracy > 30) return INVALID_RESULT;
    double theta = (double)theta_input;
    double div = floor(theta / (2.0 * PI));
    theta = theta - 2.0 * div * PI;
    double sum = 0.0;
    for (long r = 0; r < accuracy; r++) {
        long exponent = mode == 0 ? 2 * r + 1 : 2 * r;
        double sign = r % 2 == 0 ? 1.0 : -1.0;
        sum += sign * pow(theta, (double)exponent) / factorial(exponent);
    }
    return sum;
}
