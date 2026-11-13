#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 6;
bool integer_field(double x, int low, int high, int& value) noexcept {
    if (!std::isfinite(x) || x < low || x > high || std::trunc(x) != x) return false;
    value = static_cast<int>(x);
    return true;
}
double sample(int id, double x) noexcept {
    if (id == 0) return x * x * x * x;
    if (id == 1) return std::sin(x);
    return 1.0 / (1.0 + x * x);
}
double simpson(double a, double b, double fa, double fm, double fb) noexcept {
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0;
}
double refine(int id, double a, double b, double fa, double fm, double fb,
              double whole, double tolerance, int depth) noexcept {
    const double middle = (a + b) * 0.5;
    const double left_middle = (a + middle) * 0.5;
    const double right_middle = (middle + b) * 0.5;
    const double flm = sample(id, left_middle), frm = sample(id, right_middle);
    const double left = simpson(a, middle, fa, flm, fm);
    const double right = simpson(middle, b, fm, frm, fb);
    const double delta = left + right - whole;
    if (depth == 0 || std::abs(delta) <= 15.0 * tolerance)
        return left + right + delta / 15.0;
    return refine(id, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1) +
           refine(id, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1);
}
}

extern "C" std::int64_t adaptive_simpson_quadrature(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length != 5 || input_length > max_input_length) return -1;
    int id, a_micro, b_micro, exponent, depth;
    if (!integer_field(input[0], 0, 2, id) ||
        !integer_field(input[1], -2000000, 2000000, a_micro) ||
        !integer_field(input[2], -2000000, 2000000, b_micro) ||
        !integer_field(input[3], 7, 8, exponent) ||
        !integer_field(input[4], 8, 12, depth) || a_micro > b_micro) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    const double a = static_cast<double>(a_micro) / 1000000.0;
    const double b = static_cast<double>(b_micro) / 1000000.0;
    double tolerance = 1.0;
    for (int i = 0; i < exponent; ++i) tolerance *= 0.1;
    double answer = 0.0;
    if (a != b) {
        const double middle = (a + b) * 0.5;
        const double fa = sample(id, a), fm = sample(id, middle), fb = sample(id, b);
        answer = refine(id, a, b, fa, fm, fb, simpson(a, b, fa, fm, fb), tolerance, depth);
    }
    if (!std::isfinite(answer)) return -1;
    output[0] = answer;
    return 1;
}
