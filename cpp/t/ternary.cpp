#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 6;
constexpr double invalid_result = -1.0e300;

double objective(std::int64_t operation, double x) noexcept {
    const double delta = operation == 0 ? x - 1.0 : x + 1.0;
    const double square = delta * delta;
    return operation == 0 ? -square : square;
}

double ternary_search(std::int64_t operation, double a, double b, double epsilon,
                      std::int64_t frame, std::int64_t max_calls) noexcept {
    if (std::fabs(a - b) <= epsilon) return objective(operation, (a + b) / 2.0);

    const double left = (2.0 * a + b) / 3.0;
    const double right = (a + 2.0 * b) / 3.0;
    const double left_value = objective(operation, left);
    const double right_value = objective(operation, right);
    const bool take_left = operation == 0 ? left_value < right_value : left_value > right_value;
    if (frame >= max_calls) return invalid_result;
    if (take_left) return ternary_search(operation, left, b, epsilon, frame + 1, max_calls);
    return ternary_search(operation, a, right, epsilon, frame + 1, max_calls);
}
}

extern "C" double ternary(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 5 || length > max_input_length) return invalid_result;
    const auto operation = input[0];
    const auto a_milli = input[1];
    const auto b_milli = input[2];
    const auto epsilon_micro = input[3];
    const auto max_calls = input[4];
    if (length != 5 || (operation != 0 && operation != 1) ||
        a_milli < -1'000'000 || a_milli > b_milli || b_milli > 1'000'000 ||
        epsilon_micro < 1 || epsilon_micro > 1'000'000 || max_calls < 1 || max_calls > 64)
        return invalid_result;

    return ternary_search(operation, static_cast<double>(a_milli) / 1000.0,
                          static_cast<double>(b_milli) / 1000.0,
                          static_cast<double>(epsilon_micro) / 1'000'000.0, 1, max_calls);
}
