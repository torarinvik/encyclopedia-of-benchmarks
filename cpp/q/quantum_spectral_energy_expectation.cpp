#include <array>
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::int64_t scale = 256;
constexpr double invalid_result = -1.0e300;
constexpr double tau = 6.283185307179586476925286766559005768;

void fft(std::array<double, max_n>& real, std::array<double, max_n>& imag,
         std::size_t n, bool inverse) noexcept {
    std::size_t j = 0;
    for (std::size_t i = 1; i < n; ++i) {
        std::size_t bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { std::swap(real[i], real[j]); std::swap(imag[i], imag[j]); }
    }
    for (std::size_t width = 2; width <= n; width <<= 1) {
        const double angle = (inverse ? 1.0 : -1.0) * tau / static_cast<double>(width);
        const double step_real = std::cos(angle), step_imag = std::sin(angle);
        const std::size_t half = width >> 1;
        for (std::size_t start = 0; start < n; start += width) {
            double twiddle_real = 1.0, twiddle_imag = 0.0;
            for (std::size_t offset = 0; offset < half; ++offset) {
                const std::size_t even = start + offset, odd = even + half;
                const double odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                const double odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                real[odd] = real[even] - odd_real;
                imag[odd] = imag[even] - odd_imag;
                real[even] += odd_real;
                imag[even] += odd_imag;
                const double next_real = twiddle_real * step_real - twiddle_imag * step_imag;
                twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) for (std::size_t i = 0; i < n; ++i) {
        real[i] /= static_cast<double>(n); imag[i] /= static_cast<double>(n);
    }
}
}

extern "C" double quantum_spectral_energy_expectation(const std::int64_t* values,
                                                       std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > 98) return invalid_result;
    const std::int64_t n_value = values[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n)
        || (n_value & (n_value - 1)) != 0) return invalid_result;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + 3 * n) return invalid_result;

    std::int64_t norm = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto potential = values[1 + i];
        const auto real_q = values[1 + n + i];
        const auto imag_q = values[1 + 2 * n + i];
        if (potential < -2048 || potential > 2048 || real_q < -2048 || real_q > 2048
            || imag_q < -2048 || imag_q > 2048) return invalid_result;
        norm += real_q * real_q + imag_q * imag_q;
    }
    if (norm != scale * scale * static_cast<std::int64_t>(n)) return invalid_result;

    std::array<double, max_n> real{}, imag{};
    for (std::size_t i = 0; i < n; ++i) {
        real[i] = static_cast<double>(values[1 + n + i]) / scale;
        imag[i] = static_cast<double>(values[1 + 2 * n + i]) / scale;
    }
    fft(real, imag, n, false);
    for (std::size_t i = 0; i < n; ++i) {
        const auto frequency = i <= n / 2 ? static_cast<std::int64_t>(i)
                                           : static_cast<std::int64_t>(i) - static_cast<std::int64_t>(n);
        const double wave_number = tau * static_cast<double>(frequency);
        const double multiplier = 0.5 * wave_number * wave_number;
        real[i] *= multiplier; imag[i] *= multiplier;
    }
    fft(real, imag, n, true);

    double total = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const double psi_real = static_cast<double>(values[1 + n + i]) / scale;
        const double psi_imag = static_cast<double>(values[1 + 2 * n + i]) / scale;
        const double potential = static_cast<double>(values[1 + i]) / scale;
        total += psi_real * (real[i] + potential * psi_real)
               + psi_imag * (imag[i] + potential * psi_imag);
    }
    return total / static_cast<double>(n);
}
