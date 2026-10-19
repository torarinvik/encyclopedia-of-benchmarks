#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_count = 4;
constexpr std::size_t max_roots = 3;

int solve_cubic(const double *input, double roots[max_roots])
{
    const double a = input[0], b = input[1], c = input[2], d = input[3];
    const double a1 = b / a, a2 = c / a, a3 = d / a;
    const double q = (a1 * a1 - 3.0 * a2) / 9.0;
    const double r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0;
    const double discriminant = r * r - q * q * q;
    if (discriminant == 0.0) return -1;
    if (discriminant <= 0.0) {
        const double theta = std::acos(r / std::sqrt(q * q * q));
        const double pi = std::acos(-1.0);
        roots[0] = -2.0 * std::sqrt(q) * std::cos(theta / 3.0) - a1 / 3.0;
        roots[1] = -2.0 * std::sqrt(q) * std::cos((theta + 2.0 * pi) / 3.0) - a1 / 3.0;
        roots[2] = -2.0 * std::sqrt(q) * std::cos((theta + 4.0 * pi) / 3.0) - a1 / 3.0;
        return 3;
    }
    double root = std::pow(std::sqrt(discriminant) + std::fabs(r), 1.0 / 3.0);
    root += q / root;
    root *= r < 0.0 ? 1.0 : -1.0;
    roots[0] = root - a1 / 3.0;
    return 1;
}
}

extern "C" std::int64_t mibench_automotive_basicmath_cubic(
    const double *input, std::size_t input_length, double *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length != input_count) return -1;
    for (std::size_t index = 0; index < input_count; ++index)
        if (!(input[index] >= -100.0 && input[index] <= 100.0)) return -1;
    if (input[0] > -1.0 && input[0] < 1.0) return -1;

    double roots[max_roots];
    const int count = solve_cubic(input, roots);
    if (count < 0) return -1;
    if (output == nullptr || output_capacity < static_cast<std::size_t>(count)) return -2;
    for (int index = 0; index < count; ++index) output[index] = roots[index];
    return count;
}
