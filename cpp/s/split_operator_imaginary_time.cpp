#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxSteps = 8;
constexpr std::size_t kMaxInputLength = 2 + 4 * kMaxN;
constexpr double kTau = 6.28318530717958647692528676655900577;

bool bounded_integer(double value, double minimum, double maximum) {
    return std::isfinite(value) && std::trunc(value) == value
        && value >= minimum && value <= maximum;
}

void fft(std::array<double, kMaxN>& real, std::array<double, kMaxN>& imag,
         std::size_t n, bool inverse) {
    std::size_t reverse = 0;
    for (std::size_t position = 1; position < n; ++position) {
        std::size_t bit = n >> 1;
        for (; bit != 0 && (reverse & bit) != 0; bit >>= 1) reverse ^= bit;
        reverse ^= bit;
        if (position < reverse) {
            std::swap(real[position], real[reverse]);
            std::swap(imag[position], imag[reverse]);
        }
    }
    for (std::size_t block = 2; block <= n; block <<= 1) {
        const double angle = (inverse ? 1.0 : -1.0) * kTau / static_cast<double>(block);
        const double step_real = std::cos(angle), step_imag = std::sin(angle);
        for (std::size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (std::size_t offset = 0; offset < block / 2; ++offset) {
                const auto first = start + offset, second = first + block / 2;
                const double product_real = weight_real * real[second] - weight_imag * imag[second];
                const double product_imag = weight_real * imag[second] + weight_imag * real[second];
                const double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) for (std::size_t i = 0; i < n; ++i) {
        real[i] /= static_cast<double>(n);
        imag[i] /= static_cast<double>(n);
    }
}

void normalize(std::array<double, kMaxN>& real, std::array<double, kMaxN>& imag,
               std::size_t n) {
    double norm_squared = 0.0;
    for (std::size_t i = 0; i < n; ++i) norm_squared += real[i] * real[i] + imag[i] * imag[i];
    const double norm = std::sqrt(norm_squared);
    for (std::size_t i = 0; i < n; ++i) { real[i] /= norm; imag[i] /= norm; }
}
}  // namespace

extern "C" std::int64_t split_operator_imaginary_time(const double* input,
    std::size_t length, double* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (!bounded_integer(input[0], 2.0, kMaxN) || !bounded_integer(input[1], 0.0, kMaxSteps)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto steps = static_cast<std::size_t>(input[1]);
    if ((n & (n - 1)) != 0 || length != 2 + 4 * n) return -1;
    for (std::size_t i = 2; i < length; ++i) if (!std::isfinite(input[i])) return -1;
    const auto momentum_start = 2 + n, state_start = 2 + 2 * n, output_count = 2 * n;
    double norm_squared = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const double position = input[2 + i], momentum = input[momentum_start + i];
        const double real = input[state_start + 2 * i], imag = input[state_start + 2 * i + 1];
        if (position < 0.25 || position > 1.0 || momentum < 0.25 || momentum > 1.0
            || std::abs(real) > 1.0 || std::abs(imag) > 1.0) return -1;
        norm_squared += real * real + imag * imag;
    }
    if (!(norm_squared > 0.0)) return -1;
    if (output == nullptr || capacity < output_count) return -2;

    std::array<double, kMaxN> real{}, imag{};
    for (std::size_t i = 0; i < n; ++i) {
        real[i] = input[state_start + 2 * i];
        imag[i] = input[state_start + 2 * i + 1];
    }
    normalize(real, imag, n);
    for (std::size_t step = 0; step < steps; ++step) {
        for (std::size_t i = 0; i < n; ++i) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        fft(real, imag, n, false);
        for (std::size_t i = 0; i < n; ++i) {
            real[i] *= input[momentum_start + i]; imag[i] *= input[momentum_start + i];
        }
        fft(real, imag, n, true);
        for (std::size_t i = 0; i < n; ++i) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        normalize(real, imag, n);
    }
    for (std::size_t i = 0; i < n; ++i) { output[2 * i] = real[i]; output[2 * i + 1] = imag[i]; }
    return static_cast<std::int64_t>(output_count);
}
