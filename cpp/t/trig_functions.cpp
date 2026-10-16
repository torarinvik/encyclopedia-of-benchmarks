#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr double pi = 3.14159265358979323846;
double rounded_six(double value) {
    const double magnitude = std::floor(std::fabs(value) * 1000000.0 + 0.5) / 1000000.0;
    return value < 0.0 ? -magnitude : magnitude;
}
double integer_power(double value, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; ++i) result *= value;
    return result;
}
double factorial_double(int n) {
    double result = 1.0;
    for (int i = 2; i <= n; ++i) result *= static_cast<double>(i);
    return result;
}
double trig_series(double value, double tolerance, int kind) {
    const double period = 2.0 * pi;
    while (value >= period) value -= period;
    while (value <= -period) value += period;
    double result = 0.0, previous = 1.0;
    int step = 0;
    while (std::fabs(previous - result) > tolerance) {
        previous = result;
        const int power = 2 * step + kind;
        const double term = integer_power(value, power) / factorial_double(power);
        result += step % 2 == 0 ? term : -term;
        ++step;
    }
    return rounded_six(result);
}
}

extern "C" std::int64_t trig_functions(const double* input, std::size_t length,
                                       double* output, std::size_t capacity) {
    if (input == nullptr || length != 3) return -1;
    const double selector_value = input[0], raw_x = input[1], tolerance = input[2];
    if (!std::isfinite(selector_value) || selector_value < 0.0 || selector_value > 7.0 || std::floor(selector_value) != selector_value) return -1;
    if (!std::isfinite(tolerance) || tolerance < 1e-9 || tolerance > 1e-2) return -1;
    if (std::isfinite(raw_x) && (raw_x < -10000.0 || raw_x > 10000.0)) return -1;
    if (output == nullptr || capacity < 1) return -2;
    if (!std::isfinite(raw_x)) { output[0] = std::numeric_limits<double>::quiet_NaN(); return 1; }

    const int selector = static_cast<int>(selector_value);
    double x = raw_x;
    if (selector == 2 || selector == 3 || selector == 6 || selector == 7) x = x * pi / 180.0;
    double sine_value, cosine_value, result;
    if (selector == 0 || selector == 2) result = trig_series(x, tolerance, 1);
    else if (selector == 1 || selector == 3) result = trig_series(x, tolerance, 0);
    else if (selector == 4 || selector == 6) {
        cosine_value = trig_series(x, tolerance, 0);
        result = cosine_value == 0.0 ? std::numeric_limits<double>::quiet_NaN() : trig_series(x, tolerance, 1) / cosine_value;
    } else {
        sine_value = trig_series(x, tolerance, 1);
        result = sine_value == 0.0 ? std::numeric_limits<double>::quiet_NaN() : trig_series(x, tolerance, 0) / sine_value;
    }
    output[0] = result;
    return 1;
}
