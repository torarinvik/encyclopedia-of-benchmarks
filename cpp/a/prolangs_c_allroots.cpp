#include <cstddef>
#include <cstdint>
#include <cstring>
#include <cmath>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t required_bytes = 24;
constexpr double newton_epsilon = 5.0e-6;
constexpr int max_newton_iterations = 40;

double absolute_value(double value) { return value < 0.0 ? -value : value; }

double horner_value_and_derivative(int degree, const double* coefficients,
                                   double x, double& derivative) {
    double value = coefficients[degree];
    double slope = value;
    for (int j = degree - 1; j >= 1; --j) {
        value = x * value + coefficients[j];
        slope = x * slope + value;
    }
    value = x * value + coefficients[0];
    derivative = slope;
    return value;
}

double newton_root(int degree, const double* coefficients, double lower, double upper) {
    if (upper < lower) { const double temporary = lower; lower = upper; upper = temporary; }
    double previous = lower;
    double current = (lower + upper) / 2.0;
    int iterations = 0;
    while (absolute_value(current - previous) / absolute_value(current) > newton_epsilon &&
           iterations <= max_newton_iterations) {
        previous = current;
        double derivative = 0.0;
        const double value = horner_value_and_derivative(degree, coefficients, current, derivative);
        current -= value / derivative;
        ++iterations;
    }
    return current;
}

void store_f64_le(double value, std::uint8_t* output, std::size_t offset) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8u * i));
}

void solve(std::uint8_t* output) {
    const double original[4] = {4.0, -4.0, -1.0, 1.0};
    double coefficients[4];
    std::memcpy(coefficients, original, sizeof(coefficients));
    double upper = 0.0;
    for (int i = 0; i <= 3; ++i) upper += absolute_value(coefficients[i]);
    upper /= absolute_value(coefficients[3]);
    const double lower = -upper - 1.0;

    const double first_root = newton_root(3, coefficients, lower, upper);
    double deflated[3] = {0.0, 0.0, 0.0};
    deflated[2] = coefficients[3];
    for (int i = 1; i >= 0; --i) deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1];

    const double discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0];
    const double plus_root = (-deflated[1] + std::sqrt(discriminant)) / (2.0 * deflated[2]);
    const double minus_root = (-deflated[1] - std::sqrt(discriminant)) / (2.0 * deflated[2]);
    const double refined_plus = newton_root(3, original, plus_root - 0.5, plus_root + 0.5);
    const double refined_minus = newton_root(3, original, minus_root - 0.5, minus_root + 0.5);
    store_f64_le(first_root, output, 0);
    store_f64_le(refined_plus, output, 8);
    store_f64_le(refined_minus, output, 16);
}
} // namespace

extern "C" std::int64_t prolangs_c_allroots(const std::int64_t* values, std::size_t length,
                                             std::uint8_t* output, std::size_t output_capacity) {
    if (values == nullptr || length != 4 || values[0] != 4 || values[1] != -4 ||
        values[2] != -1 || values[3] != 1) return invalid_result;
    if (output == nullptr || output_capacity < required_bytes) return output_error;
    std::uint8_t staged[required_bytes];
    solve(staged);
    std::memcpy(output, staged, required_bytes);
    return static_cast<std::int64_t>(required_bytes);
}
