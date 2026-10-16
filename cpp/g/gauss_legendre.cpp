#include <array>
#include <cmath>

namespace {
constexpr int max_iterations = 8;
constexpr double invalid_result = -1.0e300;

double pi_after_iterations(int iterations) {
    double a = 1.0;
    double b = std::sqrt(0.5);
    double t = 0.25;
    double p = 1.0;
    for (int index = 0; index < iterations; ++index) {
        std::array<double, 4> values{};
        values[0] = (a + b) / 2.0;
        values[1] = std::sqrt(a * b);
        const double difference = a - values[0];
        values[2] = t - p * difference * difference;
        values[3] = 2.0 * p;
        a = values[0];
        b = values[1];
        t = values[2];
        p = values[3];
    }
    const double sum = a + b;
    return sum * sum / (4.0 * t);
}
}

extern "C" double gauss_legendre(double iterations_value) noexcept {
    if (!(iterations_value >= 0.0 && iterations_value <= max_iterations)
            || iterations_value != static_cast<double>(static_cast<int>(iterations_value))) return invalid_result;
    return pi_after_iterations(static_cast<int>(iterations_value));
}
