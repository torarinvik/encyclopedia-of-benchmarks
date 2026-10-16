#include <math.h>
#include <stddef.h>
#include <stdint.h>

static double rounded_six(double value) {
    double magnitude = floor(fabs(value) * 1000000.0 + 0.5) / 1000000.0;
    return value < 0.0 ? -magnitude : magnitude;
}

static double integer_power(double value, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; ++i) result *= value;
    return result;
}

static double factorial_double(int n) {
    double result = 1.0;
    for (int i = 2; i <= n; ++i) result *= (double)i;
    return result;
}

static double trig_series(double value, double tolerance, int kind) {
    const double period = 2.0 * 3.14159265358979323846;
    while (value >= period) value -= period;
    while (value <= -period) value += period;
    double result = 0.0, previous = 1.0;
    int step = 0;
    while (fabs(previous - result) > tolerance) {
        previous = result;
        int power = 2 * step + kind;
        double term = integer_power(value, power) / factorial_double(power);
        result += (step % 2 == 0 ? term : -term);
        ++step;
    }
    return rounded_six(result);
}

int64_t trig_functions(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    double selector_value = input[0], x = input[1], tolerance = input[2];
    if (!isfinite(selector_value) || selector_value < 0.0 || selector_value > 7.0 || floor(selector_value) != selector_value) return -1;
    if (!isfinite(tolerance) || tolerance < 1e-9 || tolerance > 1e-2) return -1;
    if (isfinite(x) && (x < -10000.0 || x > 10000.0)) return -1;
    if (output == NULL || capacity < 1) return -2;
    if (!isfinite(x)) { output[0] = NAN; return 1; }

    int selector = (int)selector_value;
    if (selector == 2 || selector == 3 || selector == 6 || selector == 7)
        x = x * 3.14159265358979323846 / 180.0;
    double sine_value, cosine_value, result;
    switch (selector) {
        case 0: case 2: result = trig_series(x, tolerance, 1); break;
        case 1: case 3: result = trig_series(x, tolerance, 0); break;
        case 4: case 6:
            cosine_value = trig_series(x, tolerance, 0);
            result = cosine_value == 0.0 ? NAN : trig_series(x, tolerance, 1) / cosine_value;
            break;
        default:
            sine_value = trig_series(x, tolerance, 1);
            result = sine_value == 0.0 ? NAN : trig_series(x, tolerance, 0) / sine_value;
            break;
    }
    output[0] = result;
    return 1;
}
