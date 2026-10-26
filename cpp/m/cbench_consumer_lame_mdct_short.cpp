#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double kPi = 3.14159265358979323846264338327950288;
constexpr double kEnwindowMax = 0.030526638;
}

extern "C" std::int64_t cbench_consumer_lame_mdct_short(
    const double *input, std::size_t input_length, double *output, std::size_t output_capacity) noexcept {
    if (!input || input_length == 0 || input_length > 19) return -1;
    for (std::size_t i = 0; i < input_length; ++i)
        if (!std::isfinite(input[i]) || input[i] < -32768.0 || input[i] > 32768.0) return -1;
    if (input_length != 18) return -1;

    std::array<std::array<double, 6>, 6> coefficients{};
    const double scale = 4.0 / 12.0;
    for (std::size_t i = 0; i < 3; ++i) {
        const double w2 = std::cos(kPi / 12.0 * (static_cast<double>(i) + 0.5)) * kEnwindowMax / 32768.0 * scale;
        for (std::size_t m = 0; m < 6; ++m) {
            coefficients[m][i] = w2 * std::cos((kPi / 48.0) * static_cast<double>(2 * m + 1) * static_cast<double>(4 * i + 14));
            coefficients[m][i + 3] = w2 * std::cos((kPi / 48.0) * static_cast<double>(2 * m + 1) * static_cast<double>(4 * i + 38));
        }
    }
    std::array<double, 18> staged{};
    for (int m = 5; m >= 0; --m) for (int l = 2; l >= 0; --l) {
        const std::size_t base = 6 * static_cast<std::size_t>(l);
        double sum = coefficients[static_cast<std::size_t>(m)][0] * input[base];
        for (std::size_t i = 1; i < 6; ++i) sum += coefficients[static_cast<std::size_t>(m)][i] * input[base + i];
        staged[3 * static_cast<std::size_t>(m) + static_cast<std::size_t>(l)] = sum;
    }
    if (!output || output_capacity < 18) return -2;
    for (std::size_t i = 0; i < staged.size(); ++i) output[i] = staged[i];
    return 18;
}
