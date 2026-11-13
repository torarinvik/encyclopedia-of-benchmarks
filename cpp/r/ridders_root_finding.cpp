#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 6;
bool integer_field(double value, int low, int high, int& decoded) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}
double polynomial(int id, double x) noexcept {
    if (id == 0) return x * x - 2.0;
    if (id == 1) return x * x * x - 2.0;
    if (id == 2) return x * x * x + x - 1.0;
    return x;
}
bool opposite(double a, double b) noexcept { return (a < 0.0) != (b < 0.0); }
int solve(int id, double left, double right, double tolerance, int iterations,
          double& root) noexcept {
    double f_left = polynomial(id, left), f_right = polynomial(id, right);
    if (f_left == 0.0) { root = left; return 1; }
    if (f_right == 0.0) { root = right; return 1; }
    for (int step = 0; step < iterations; ++step) {
        if (right - left <= tolerance) { root = (left + right) * 0.5; return 1; }
        const double middle = (left + right) * 0.5;
        const double f_middle = polynomial(id, middle);
        if (f_middle == 0.0) { root = middle; return 1; }
        const double radicand = f_middle * f_middle - f_left * f_right;
        if (!std::isfinite(radicand) || radicand <= 0.0) return -3;
        const double denominator = std::sqrt(radicand);
        if (!std::isfinite(denominator) || denominator == 0.0) return -3;
        const double direction = f_left < f_right ? -1.0 : 1.0;
        const double candidate = middle + (middle - left) * direction * f_middle / denominator;
        if (!std::isfinite(candidate) || !(left < candidate && candidate < right)) return -3;
        const double f_candidate = polynomial(id, candidate);
        if (f_candidate == 0.0) { root = candidate; return 1; }
        if (opposite(f_left, f_candidate)) { right = candidate; f_right = f_candidate; }
        else { left = candidate; f_left = f_candidate; }
        if (right - left <= tolerance) { root = (left + right) * 0.5; return 1; }
    }
    return -3;
}
}

extern "C" std::int64_t ridders_root_finding(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length != 5 || input_length > max_input_length) return -1;
    int id, left_milli, right_milli, tolerance_micro, iterations;
    if (!integer_field(input[0], 0, 3, id) ||
        !integer_field(input[1], -3000, 3000, left_milli) ||
        !integer_field(input[2], -3000, 3000, right_milli) ||
        !integer_field(input[3], 1, 1000, tolerance_micro) ||
        !integer_field(input[4], 24, 32, iterations) || left_milli >= right_milli) return -1;
    const double left = left_milli / 1000.0, right = right_milli / 1000.0;
    const double f_left = polynomial(id, left), f_right = polynomial(id, right);
    if (f_left != 0.0 && f_right != 0.0 && !opposite(f_left, f_right)) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    double root = 0.0;
    const int status = solve(id, left, right, tolerance_micro / 1000000.0, iterations, root);
    if (status != 1 || !std::isfinite(root)) return status == 1 ? -3 : status;
    output[0] = root;
    return 1;
}
